Here's a Solidity smart contract named `AetherForge`, designed around the concept of "Adaptive & Self-Governing Digital Asset Fabricator." It aims to create dynamic, evolving digital assets (AetherFragments) that adapt based on user interactions, system catalysts (simulated external data), and community governance. It includes an internal resource token (AetherDust) and a reputation system.

This contract integrates multiple advanced concepts:
*   **Dynamic NFTs/SFTs:** AetherFragments have mutable "Ephemeral Traits" that evolve.
*   **On-Chain State Complexity:** Fragments maintain detailed state including immutable "Genes," mutable "Traits," and a "Catalyst History."
*   **Gamified Evolution:** Users actively trigger evolution, trait cultivation, and resource management.
*   **Simulated Oracle Integration:** A `CatalystInjector` role simulates external data feeds influencing asset behavior.
*   **Decentralized Governance:** A proposal system allows AetherDust holders to vote on key system parameters that directly affect fabrication and evolution.
*   **Reputation System (SocialFi):** User reputation influences their ability to propose and is rewarded/penalized by participation.
*   **Internal Resource Management:** AetherDust serves as the economic backbone for actions within the ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For burn function compatibility

// Outline: AetherForge - Adaptive & Self-Governing Digital Asset Fabricator
// This contract enables the creation, evolution, and governance of dynamic digital assets called "AetherFragments".
// These fragments possess both immutable "Genes" and mutable "Ephemeral Traits" that adapt based on user interactions,
// system catalysts (simulated external data), and community governance. The system includes a resource token ("AetherDust")
// and a reputation system to drive participation and control.

// Function Summary:

// I. Core Fabrication & Asset Management (ERC-721-like for unique fragments):
// 1.  constructor(): Initializes contract, roles, initial parameters, and AetherDust.
// 2.  synthesizeFragment(uint256[] memory parentFragmentIds, uint8[] memory initialCatalystInfluence): Creates a new AetherFragment. Costs AetherDust. Parent fragments contribute to genes/traits.
// 3.  getFragmentDetails(uint256 fragmentId): Retrieves comprehensive details of a specific AetherFragment.
// 4.  transferFragment(address to, uint256 fragmentId): Transfers ownership of an AetherFragment.
// 5.  burnFragment(uint256 fragmentId): Destroys an AetherFragment, potentially recovering some AetherDust.

// II. Dynamic Evolution & Catalyst System:
// 6.  injectCatalyst(uint8 catalystType, uint256 influenceMagnitude, bytes memory metadata): Records a global 'catalyst' event, influencing future fragment evolution. Requires CATALYST_INJECTOR_ROLE.
// 7.  evolveFragment(uint256 fragmentId): Triggers the evolution of a fragment. Traits change based on catalysts, genes, and fragment history. Costs AetherDust.
// 8.  getPotentialEvolutionPreview(uint256 fragmentId): Provides a read-only simulation of how a fragment's traits might change upon evolution without executing it.
// 9.  decayFragmentTraits(uint256 fragmentId): Applies decay to time-sensitive traits of a fragment. Can be user-triggered with a small reward to incentivize maintenance.
// 10. cultivateNewTrait(uint256 fragmentId, uint8 traitType): Attempts to unlock a new, previously unpossessed trait for a fragment, given specific conditions (e.g., high reputation, specific catalysts). Costs AetherDust.

// III. Governance & Parameters:
// 11. proposeParameterChange(string memory description, uint8 paramType, uint256 newValue): Allows users with sufficient reputation to propose changes to system parameters.
// 12. voteOnProposal(uint256 proposalId, bool support): Casts a vote on an active proposal. Voting power is weighted by AetherDust balance.
// 13. executeProposal(uint256 proposalId): Finalizes a passed proposal, applying the proposed parameter change.
// 14. getProposalState(uint256 proposalId): Retrieves the current status (active, passed, failed, executed) of a proposal.
// 15. getParamValue(uint8 paramType): Retrieves the current value of a specific system parameter.

// IV. Resource Management (AetherDust - a basic internal token-like resource):
// 16. getAetherDustBalance(address account): Retrieves the AetherDust balance for a given address.
// 17. distributeAetherDust(address[] memory recipients, uint256[] memory amounts): Admin function to distribute AetherDust (e.g., initial grants, rewards). Requires GOVERNOR_ROLE.
// 18. depositNativeCurrencyForDust(): Allows users to deposit native currency (ETH) to mint AetherDust.
// 19. withdrawDustForNativeCurrency(uint256 amount): Allows users to burn AetherDust to withdraw native currency (ETH).

// V. Reputation & Access Control:
// 20. updateUserReputation(address user, int256 change): Adjusts a user's reputation score. Requires GOVERNOR_ROLE.
// 21. getUserReputation(address user): Retrieves the reputation score and last activity timestamp for a user.
// 22. grantRole(address user, bytes32 role): Grants a specific role (ADMIN, GOVERNOR, CATALYST_INJECTOR) to an address. Requires ADMIN_ROLE.


contract AetherForge is IERC721Receiver {

    // --- Enums and Constants ---

    enum CatalystType {
        SolarFlare,          // Strong, sudden impact on traits
        CosmicDrift,         // Slow, subtle change affecting growth
        QuantumFluctuation,  // Random, unpredictable effects, key for new discoveries
        NeuralNetworkOutput  // Simulated AI decision/data that influences evolution paths
    }

    enum TraitType {
        Resilience,          // Resistance to decay/negative catalysts
        AethericFlow,        // Efficiency in evolution/resource use
        Adaptability,        // Speed of trait change
        Luminosity,          // Aesthetic value, can impact reputation indirectly
        SynthesisEfficiency, // Improves chance of good gene inheritance
        MysticAura,          // Influences likelihood of rare events
        TemporalStability    // Resistance to rapid, chaotic changes
    }

    enum GeneType {
        GeneticDominance,    // Determines how traits are passed/influenced
        MutationRate,        // Likelihood and magnitude of trait changes during evolution
        BaseResilience,      // Baseline for Resilience trait
        ElementalAffinity    // Predisposition to certain catalyst types
    }

    enum ParamType {
        FabricationCostDust,          // Cost to synthesize a new fragment
        EvolutionCostDust,            // Cost to evolve a fragment
        GovernanceVoteThreshold,      // Minimum total Yes votes (in Dust) for a proposal to pass
        GovernanceVotingPeriod,       // Duration for a proposal's voting phase
        MinReputationForProposal,     // Minimum reputation required to create a proposal
        DustToEthRate,                // Exchange rate for AetherDust and native currency
        DecayRateMultiplier           // Multiplier for trait decay calculations
    }

    enum ProposalState {
        Pending,   // Initial state, or for non-existent proposals
        Active,    // Currently in voting period
        Passed,    // Voting period ended, Yes votes > No votes and threshold met
        Failed,    // Voting period ended, did not meet passing criteria
        Executed   // Proposal was passed and its effects applied
    }

    // --- Structs ---

    struct Gene {
        GeneType geneType;
        uint256 value; // Immutable base property, influences trait ranges
    }

    struct Trait {
        TraitType traitType;
        uint256 value;       // Mutable, ephemeral property, changes over time
        uint256 lastUpdate;  // Timestamp of last change, used for decay
    }

    struct CatalystLog {
        uint256 timestamp;
        CatalystType catalystType;
        uint256 influenceMagnitude; // How strong this catalyst was
    }

    struct AetherFragment {
        uint256 id;
        address owner;
        uint256 generation; // 0 for genesis, increments with synthesis from parents
        Gene[] genes;       // Immutable core properties, influence trait potential
        Trait[] traits;     // Mutable, evolving properties
        uint256 lastEvolutionTimestamp; // When this fragment last evolved
        CatalystLog[] catalystHistory; // A summary of catalysts that affected this fragment
        uint256 lastDecayTimestamp;   // When traits last decayed
    }

    struct Proposal {
        string description;
        address proposer;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 yesVotes; // Total AetherDust from 'yes' votes
        uint256 noVotes;  // Total AetherDust from 'no' votes
        bool executed;    // True if the proposal has been applied
        ParamType targetParamType; // Which system parameter this proposal targets
        uint224 newValue; // The new value for the target parameter (uint224 to save space)
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    struct UserReputation {
        uint256 score;
        uint256 lastActivity; // Timestamp of last reputation change or active interaction
    }

    // --- State Variables ---

    mapping(uint256 => AetherFragment) public fragments;
    uint256 private _fragmentCount; // Total number of fragments created

    // ERC-721-like ownership tracking
    mapping(uint256 => address) private _fragmentOwners;
    mapping(address => uint256) private _ownerFragmentCounts;

    // AetherDust (internal resource token-like system)
    mapping(address => uint256) public aetherDustBalances;

    // Reputation System
    mapping(address => UserReputation) public userReputations;

    // Governance System
    mapping(uint224 => Proposal) public proposals; // Using uint224 for proposal ID
    uint224 private _proposalCount; // Total number of proposals created

    // System Parameters (governable by DAO)
    mapping(ParamType => uint256) private systemParameters;

    // Role-Based Access Control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant CATALYST_INJECTOR_ROLE = keccak256("CATALYST_INJECTOR_ROLE");
    mapping(address => mapping(bytes32 => bool)) private _roles; // address => role => bool

    // Global Catalyst History (impacts all fragments)
    CatalystLog[] public globalCatalystLogs;

    // --- Events ---

    event FragmentSynthesized(uint256 indexed fragmentId, address indexed owner, uint256 generation);
    event FragmentEvolved(uint256 indexed fragmentId, address indexed owner, uint256 newTraitValueCount);
    event CatalystInjected(CatalystType indexed catalystType, uint256 influenceMagnitude, uint256 timestamp);
    event ProposalCreated(uint224 indexed proposalId, address indexed proposer, string description, uint256 votingEndTime);
    event VoteCast(uint224 indexed proposalId, address indexed voter, bool support, uint256 weightedVotes);
    event ProposalExecuted(uint224 indexed proposalId, ParamType indexed paramType, uint256 newValue);
    event AetherDustTransferred(address indexed from, address indexed to, uint256 amount);
    event AetherDustMinted(address indexed recipient, uint256 amount);
    event AetherDustBurned(address indexed burner, uint256 amount);
    event TraitCultivated(uint256 indexed fragmentId, TraitType indexed traitType, uint256 initialValue);
    event FragmentTransferred(address indexed from, address indexed to, uint256 indexed fragmentId);
    event FragmentBurned(uint256 indexed fragmentId, address indexed owner);
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore);

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        require(hasRole(msg.sender, role), "AetherForge: Caller is not authorized");
        _;
    }

    modifier fragmentExists(uint256 fragmentId) {
        require(_fragmentOwners[fragmentId] != address(0), "AetherForge: Fragment does not exist");
        _;
    }

    modifier isFragmentOwner(uint256 fragmentId) {
        require(_fragmentOwners[fragmentId] == msg.sender, "AetherForge: Caller is not fragment owner");
        _;
    }

    modifier hasEnoughDust(uint256 amount) {
        require(aetherDustBalances[msg.sender] >= amount, "AetherForge: Insufficient AetherDust");
        _;
    }

    // --- Constructor ---

    // 1. constructor()
    constructor() {
        // Grant initial ADMIN_ROLE to deployer (msg.sender)
        _roles[msg.sender][ADMIN_ROLE] = true;
        // Also grant GOVERNOR and CATALYST_INJECTOR roles to deployer for initial setup convenience
        _roles[msg.sender][GOVERNOR_ROLE] = true;
        _roles[msg.sender][CATALYST_INJECTOR_ROLE] = true;

        // Set initial system parameters (all values are in smallest unit, e.g., 10^18 for Dust/ETH)
        systemParameters[ParamType.FabricationCostDust] = 1000 * 10**18; // 1000 AetherDust
        systemParameters[ParamType.EvolutionCostDust] = 200 * 10**18;    // 200 AetherDust
        systemParameters[ParamType.GovernanceVoteThreshold] = 5000 * 10**18; // 5000 AetherDust total 'yes' votes needed
        systemParameters[ParamType.GovernanceVotingPeriod] = 3 days;     // 3 days for voting
        systemParameters[ParamType.MinReputationForProposal] = 50;       // Minimum reputation score of 50
        systemParameters[ParamType.DustToEthRate] = 100 * 10**18; // 1 ETH for 100 AetherDust (simplified oracle)
        systemParameters[ParamType.DecayRateMultiplier] = 1; // Used in decay calculation, e.g., 1 implies 1% per day for base decay

        // Mint some initial AetherDust for the deployer
        _mintDust(msg.sender, 100_000 * 10**18); // 100,000 AetherDust
        // Assign initial reputation to the deployer
        _updateReputation(msg.sender, 100);
    }

    // --- Internal Helpers for ERC-721-like functionality ---

    function _exists(uint256 fragmentId) internal view returns (bool) {
        return _fragmentOwners[fragmentId] != address(0);
    }

    function _mint(address to, uint256 fragmentId) internal {
        require(to != address(0), "AetherForge: Mint to the zero address");
        require(!_exists(fragmentId), "AetherForge: Token already minted");
        _fragmentOwners[fragmentId] = to;
        _ownerFragmentCounts[to]++;
    }

    function _burn(uint256 fragmentId) internal {
        require(_exists(fragmentId), "AetherForge: Token does not exist");
        address owner = _fragmentOwners[fragmentId];
        _ownerFragmentCounts[owner]--;
        delete _fragmentOwners[fragmentId];
        delete fragments[fragmentId]; // Clear all fragment data from storage
    }

    function _transfer(address from, address to, uint256 fragmentId) internal {
        require(from == _fragmentOwners[fragmentId], "AetherForge: Fragment transfer from incorrect owner");
        require(to != address(0), "AetherForge: Transfer to the zero address");
        
        _ownerFragmentCounts[from]--;
        _fragmentOwners[fragmentId] = to;
        _ownerFragmentCounts[to]++;
        fragments[fragmentId].owner = to; // Update owner in the fragment struct itself

        emit FragmentTransferred(from, to, fragmentId);
    }

    // --- Role Management (part of V. Reputation & Access Control) ---

    function hasRole(address account, bytes32 role) public view returns (bool) {
        return _roles[account][role];
    }

    // 22. grantRole(address user, bytes32 role)
    function grantRole(address user, bytes32 role) public onlyRole(ADMIN_ROLE) {
        require(user != address(0), "AetherForge: Cannot grant role to zero address");
        require(!_roles[user][role], "AetherForge: User already has this role");
        _roles[user][role] = true;
        // Event can be added here if desired: emit RoleGranted(role, user, msg.sender);
    }

    function revokeRole(address user, bytes32 role) public onlyRole(ADMIN_ROLE) {
        require(user != address(0), "AetherForge: Cannot revoke role from zero address");
        require(_roles[user][role], "AetherForge: User does not have this role");
        _roles[user][role] = false;
        // Event can be added here if desired: emit RoleRevoked(role, user, msg.sender);
    }


    // --- I. Core Fabrication & Asset Management ---

    // 2. synthesizeFragment(uint256[] memory parentFragmentIds, uint8[] memory initialCatalystInfluence)
    // `initialCatalystInfluence` is a simplified array of CatalystType enums to affect initial traits.
    function synthesizeFragment(uint256[] memory parentFragmentIds, uint8[] memory initialCatalystInfluence)
        public hasEnoughDust(systemParameters[ParamType.FabricationCostDust]) returns (uint256 newFragmentId)
    {
        require(parentFragmentIds.length <= 2, "AetherForge: Max 2 parent fragments allowed for synthesis");
        
        _spendDust(msg.sender, systemParameters[ParamType.FabricationCostDust]);
        _fragmentCount++;
        newFragmentId = _fragmentCount;

        // Initialize new fragment structure
        AetherFragment storage newFragment = fragments[newFragmentId];
        newFragment.id = newFragmentId;
        newFragment.owner = msg.sender;
        newFragment.lastEvolutionTimestamp = block.timestamp;
        newFragment.lastDecayTimestamp = block.timestamp;

        // Simplified Gene & Trait generation logic:
        if (parentFragmentIds.length > 0) {
            newFragment.generation = 1; // For now, any fragment with parents is generation 1
            // Combine genes from parents (e.g., direct copy from first parent for simplicity)
            for (uint256 i = 0; i < parentFragmentIds.length; i++) {
                require(_exists(parentFragmentIds[i]), "AetherForge: Parent fragment must exist");
                // In a real system, this would involve complex gene combination/mutation logic
                if (i == 0) { // For this example, only inherit from the first parent
                     for(uint256 j=0; j < fragments[parentFragmentIds[i]].genes.length; j++) {
                        newFragment.genes.push(fragments[parentFragmentIds[i]].genes[j]);
                     }
                }
            }
        } else {
            // Genesis fragment: assign default genes
            newFragment.genes.push(Gene(GeneType.BaseResilience, 50));
            newFragment.genes.push(Gene(GeneType.MutationRate, 10));
            newFragment.generation = 0; // First generation
        }

        // Apply initial catalyst influence to traits
        for (uint256 i = 0; i < initialCatalystInfluence.length; i++) {
            // Simplified: direct mapping of influence to initial traits
            TraitType tt = TraitType(i % uint8(TraitType.TemporalStability + 1)); // Cycle through available traits
            newFragment.traits.push(Trait(tt, 100 + initialCatalystInfluence[i], block.timestamp)); // Base value + influence
            newFragment.catalystHistory.push(CatalystLog(block.timestamp, CatalystType(initialCatalystInfluence[i]), initialCatalystInfluence[i]));
        }
        if (newFragment.traits.length == 0) { // Ensure at least one trait for fragments without catalysts
            newFragment.traits.push(Trait(TraitType.Resilience, 100, block.timestamp));
        }

        _mint(msg.sender, newFragmentId); // Assign ERC-721-like ownership
        emit FragmentSynthesized(newFragmentId, msg.sender, newFragment.generation);
        _updateReputation(msg.sender, 5); // Reward for contributing to fragment creation
        return newFragmentId;
    }

    // 3. getFragmentDetails(uint256 fragmentId)
    function getFragmentDetails(uint256 fragmentId)
        public view fragmentExists(fragmentId)
        returns (
            uint256 id,
            address owner,
            uint256 generation,
            Gene[] memory genes,
            Trait[] memory traits,
            uint256 lastEvolutionTimestamp,
            CatalystLog[] memory catalystHistory,
            uint256 lastDecayTimestamp
        )
    {
        AetherFragment storage f = fragments[fragmentId];
        return (
            f.id,
            f.owner,
            f.generation,
            f.genes,
            f.traits,
            f.lastEvolutionTimestamp,
            f.catalystHistory,
            f.lastDecayTimestamp
        );
    }

    // 4. transferFragment(address to, uint256 fragmentId)
    function transferFragment(address to, uint256 fragmentId) public isFragmentOwner(fragmentId) {
        _transfer(msg.sender, to, fragmentId);
        _updateReputation(msg.sender, 1); // Small reputation gain for activity
    }

    // 5. burnFragment(uint256 fragmentId)
    function burnFragment(uint256 fragmentId) public isFragmentOwner(fragmentId) {
        // Option to reclaim some AetherDust upon burning
        uint256 reclaimDustAmount = systemParameters[ParamType.FabricationCostDust] / 4; // Reclaim 25% of fabrication cost
        if (reclaimDustAmount > 0) {
            _mintDust(msg.sender, reclaimDustAmount);
        }
        _burn(fragmentId);
        emit FragmentBurned(fragmentId, msg.sender);
        _updateReputation(msg.sender, -5); // Small reputation loss for destroying a fragment
    }

    // IERC721Receiver fallback for potential future external transfers, though not strictly required for internal burns.
    function onERC721Received(
        address, // operator
        address, // from
        uint256, // tokenId
        bytes calldata // data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }


    // --- II. Dynamic Evolution & Catalyst System ---

    // 6. injectCatalyst(uint8 catalystType, uint256 influenceMagnitude, bytes memory metadata)
    function injectCatalyst(uint8 catalystType, uint256 influenceMagnitude, bytes memory metadata)
        public onlyRole(CATALYST_INJECTOR_ROLE)
    {
        // Record the catalyst in the global history, impacting all fragments upon evolution
        globalCatalystLogs.push(CatalystLog(block.timestamp, CatalystType(catalystType), influenceMagnitude));
        emit CatalystInjected(CatalystType(catalystType), influenceMagnitude, block.timestamp);
    }

    // Internal helper for applying trait decay
    function _applyDecay(AetherFragment storage f) internal {
        uint256 timeSinceDecay = block.timestamp - f.lastDecayTimestamp;
        if (timeSinceDecay == 0) return; // No time has passed, no decay

        for (uint256 i = 0; i < f.traits.length; i++) {
            Trait storage t = f.traits[i];
            // Simple decay: trait value decreases over time based on DecayRateMultiplier
            // Example: 1% decay per day (1 day * 100 in denominator)
            uint256 decayAmount = (t.value * systemParameters[ParamType.DecayRateMultiplier] * timeSinceDecay / (1 days * 100));
            if (t.value > decayAmount) {
                t.value -= decayAmount;
            } else {
                t.value = 0; // Trait cannot go below zero
            }
        }
        f.lastDecayTimestamp = block.timestamp;
    }

    // Internal helper for applying evolution logic
    function _applyEvolution(AetherFragment storage f, uint256 catalystInfluence) internal {
        // 1. Apply decay to existing traits first
        _applyDecay(f);

        // 2. Adjust traits based on catalyst influence and genes
        for (uint256 i = 0; i < f.traits.length; i++) {
            Trait storage t = f.traits[i];
            uint256 geneInfluence = 0;
            // Find relevant gene influence (e.g., MutationRate)
            for (uint256 j = 0; j < f.genes.length; j++) {
                if (f.genes[j].geneType == GeneType.MutationRate) {
                    geneInfluence = f.genes[j].value;
                    break;
                }
            }

            // Traits can increase or decrease. Simplified formula for trait change:
            // New value = current value + (catalyst_influence * mutation_rate / 1000) + random_factor
            int256 change = int256(catalystInfluence * geneInfluence / 1000); // Scale influence
            // Add some pseudo-randomness for organic-like changes
            change += int256(uint256(keccak256(abi.encodePacked(block.timestamp, f.id, t.traitType, i))) % 50 - 25);
            
            int256 newTraitValue = int256(t.value) + change;
            if (newTraitValue < 1) newTraitValue = 1; // Minimum trait value
            t.value = uint256(newTraitValue);
            t.lastUpdate = block.timestamp;
        }

        f.lastEvolutionTimestamp = block.timestamp;
        // Optionally add a summary of catalysts to fragment's history (to avoid storing all global logs)
        f.catalystHistory.push(CatalystLog(block.timestamp, CatalystType.CosmicDrift, catalystInfluence)); // Example entry
    }

    // 7. evolveFragment(uint256 fragmentId)
    function evolveFragment(uint256 fragmentId)
        public fragmentExists(fragmentId) isFragmentOwner(fragmentId)
        hasEnoughDust(systemParameters[ParamType.EvolutionCostDust])
    {
        _spendDust(msg.sender, systemParameters[ParamType.EvolutionCostDust]);
        
        AetherFragment storage f = fragments[fragmentId];

        // Gather recent global catalyst influence (simplified: average of last few global catalysts)
        uint256 totalInfluence = 0;
        uint256 count = 0;
        // Check up to the last 5 global catalysts that occurred AFTER the fragment's last evolution
        for (int i = int(globalCatalystLogs.length) - 1; i >= 0 && count < 5; i--) {
            if (globalCatalystLogs[uint256(i)].timestamp > f.lastEvolutionTimestamp) {
                totalInfluence += globalCatalystLogs[uint256(i)].influenceMagnitude;
                count++;
            }
        }
        uint256 catalystInfluence = (count > 0) ? totalInfluence / count : 0;

        _applyEvolution(f, catalystInfluence); // Apply evolution changes
        
        emit FragmentEvolved(fragmentId, msg.sender, f.traits.length);
        _updateReputation(msg.sender, 3); // Reward for actively evolving a fragment
    }

    // 8. getPotentialEvolutionPreview(uint256 fragmentId)
    function getPotentialEvolutionPreview(uint256 fragmentId)
        public view fragmentExists(fragmentId)
        returns (Trait[] memory predictedTraits)
    {
        AetherFragment storage f = fragments[fragmentId];
        
        // Simulate evolution without modifying the actual fragment state
        predictedTraits = new Trait[](f.traits.length);
        for (uint256 i = 0; i < f.traits.length; i++) {
            predictedTraits[i] = f.traits[i]; // Copy current traits
        }

        // Simulate gathering catalyst influence
        uint224 totalInfluence = 0; // Using uint224 for intermediate calculations
        uint224 count = 0;
        for (int i = int(globalCatalystLogs.length) - 1; i >= 0 && count < 5; i--) {
            if (globalCatalystLogs[uint256(i)].timestamp > f.lastEvolutionTimestamp) {
                totalInfluence += globalCatalystLogs[uint256(i)].influenceMagnitude;
                count++;
            }
        }
        uint256 catalystInfluence = (count > 0) ? totalInfluence / count : 0;

        // Simulate decay first
        uint256 timeSinceLastDecayForPreview = block.timestamp - f.lastDecayTimestamp;
        for (uint256 i = 0; i < predictedTraits.length; i++) {
            uint256 decayAmount = (predictedTraits[i].value * systemParameters[ParamType.DecayRateMultiplier] * timeSinceLastDecayForPreview / (1 days * 100));
            if (predictedTraits[i].value > decayAmount) {
                predictedTraits[i].value -= decayAmount;
            } else {
                predictedTraits[i].value = 0;
            }
        }

        // Simulate evolution changes based on current traits + catalysts
        for (uint256 i = 0; i < predictedTraits.length; i++) {
            Trait storage t = predictedTraits[i]; // Use local storage for mutable simulation
            uint256 geneInfluence = 0;
            for (uint256 j = 0; j < f.genes.length; j++) {
                if (f.genes[j].geneType == GeneType.MutationRate) {
                    geneInfluence = f.genes[j].value;
                    break;
                }
            }
            int256 change = int256(catalystInfluence * geneInfluence / 1000);
            // Use different hash for preview randomness to distinguish from actual evolution
            change += int256(uint256(keccak256(abi.encodePacked(block.timestamp, f.id, t.traitType, "preview", i))) % 50 - 25);
            
            int256 newTraitValue = int256(t.value) + change;
            if (newTraitValue < 1) newTraitValue = 1;
            t.value = uint256(newTraitValue);
        }
    }

    // 9. decayFragmentTraits(uint256 fragmentId)
    // Allows any user to trigger decay for a fragment, incentivized by a small dust reward.
    // This offloads the cost of maintaining fragment state to anyone, keeping data fresh.
    function decayFragmentTraits(uint256 fragmentId) public fragmentExists(fragmentId) {
        AetherFragment storage f = fragments[fragmentId];
        _applyDecay(f);
        // Reward caller for helping maintain the ecosystem's state
        _mintDust(msg.sender, 1 * 10**18); // 1 AetherDust reward
    }

    // 10. cultivateNewTrait(uint256 fragmentId, uint8 traitType)
    function cultivateNewTrait(uint256 fragmentId, uint8 traitType)
        public fragmentExists(fragmentId) isFragmentOwner(fragmentId)
        hasEnoughDust(systemParameters[ParamType.EvolutionCostDust] * 2) // Higher cost for a new trait
    {
        AetherFragment storage f = fragments[fragmentId];

        // Check if trait already exists on this fragment
        for (uint256 i = 0; i < f.traits.length; i++) {
            require(f.traits[i].traitType != TraitType(traitType), "AetherForge: Fragment already possesses this trait");
        }

        // Complex conditions for cultivating a new trait (examples):
        // 1. Fragment must have evolved recently (e.g., within 7 days)
        require(f.lastEvolutionTimestamp > block.timestamp - 7 days, "AetherForge: Fragment needs recent evolution to cultivate new traits");
        // 2. Owner must have a minimum reputation score
        require(userReputations[msg.sender].score >= systemParameters[ParamType.MinReputationForProposal], "AetherForge: Insufficient reputation to cultivate");
        // 3. A specific global catalyst must have been injected recently (e.g., QuantumFluctuation for unpredictability)
        bool recentQuantumFluctuation = false;
        for (int i = int(globalCatalystLogs.length) - 1; i >= 0 && i >= int(globalCatalystLogs.length) - 10; i--) { // Check last 10 global catalysts
            if (globalCatalystLogs[uint256(i)].catalystType == CatalystType.QuantumFluctuation &&
                globalCatalystLogs[uint256(i)].timestamp > block.timestamp - 3 days) {
                recentQuantumFluctuation = true;
                break;
            }
        }
        require(recentQuantumFluctuation, "AetherForge: QuantumFluctuation catalyst required for new trait cultivation");

        _spendDust(msg.sender, systemParameters[ParamType.EvolutionCostDust] * 2);

        // Add the new trait with an initial value
        f.traits.push(Trait(TraitType(traitType), 150, block.timestamp));
        emit TraitCultivated(fragmentId, TraitType(traitType), 150);
        _updateReputation(msg.sender, 10); // Higher reward for discovering/cultivating new traits
    }


    // --- III. Governance & Parameters ---

    // 11. proposeParameterChange(string memory description, uint8 paramType, uint256 newValue)
    function proposeParameterChange(string memory description, uint8 paramType, uint256 newValue)
        public
    {
        require(userReputations[msg.sender].score >= systemParameters[ParamType.MinReputationForProposal], "AetherForge: Insufficient reputation to propose");
        
        _proposalCount++;
        uint224 proposalId = _proposalCount; // Cast to uint224

        Proposal storage p = proposals[proposalId];
        p.description = description;
        p.proposer = msg.sender;
        p.creationTime = block.timestamp;
        p.votingEndTime = block.timestamp + systemParameters[ParamType.GovernanceVotingPeriod];
        p.targetParamType = ParamType(paramType);
        p.newValue = uint224(newValue); // Store the new value (cast to uint224 to fit)

        emit ProposalCreated(proposalId, msg.sender, description, p.votingEndTime);
        _updateReputation(msg.sender, 5); // Reward for engaging in governance
    }

    // 12. voteOnProposal(uint256 proposalId, bool support)
    function voteOnProposal(uint224 proposalId, bool support) public {
        Proposal storage p = proposals[proposalId];
        require(p.proposer != address(0), "AetherForge: Proposal does not exist");
        require(block.timestamp <= p.votingEndTime, "AetherForge: Voting period has ended");
        require(!p.hasVoted[msg.sender], "AetherForge: User has already voted on this proposal");
        require(aetherDustBalances[msg.sender] > 0, "AetherForge: No AetherDust to vote with"); // Requires AetherDust balance to vote

        uint256 votingPower = aetherDustBalances[msg.sender];
        if (support) {
            p.yesVotes += votingPower;
        } else {
            p.noVotes += votingPower;
        }
        p.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, votingPower);
        _updateReputation(msg.sender, 1); // Small reputation for casting a vote
    }

    // 13. executeProposal(uint256 proposalId)
    function executeProposal(uint224 proposalId) public {
        Proposal storage p = proposals[proposalId];
        require(p.proposer != address(0), "AetherForge: Proposal does not exist");
        require(block.timestamp > p.votingEndTime, "AetherForge: Voting period has not ended yet");
        require(!p.executed, "AetherForge: Proposal already executed");

        if (p.yesVotes > p.noVotes && p.yesVotes >= systemParameters[ParamType.GovernanceVoteThreshold]) {
            // Proposal passed: apply the parameter change
            systemParameters[p.targetParamType] = p.newValue;
            p.executed = true;
            emit ProposalExecuted(proposalId, p.targetParamType, p.newValue);
            _updateReputation(p.proposer, 20); // Higher reward for a successfully passed proposal
        } else {
            // Proposal failed
            p.executed = true; // Mark as executed even if failed to prevent re-execution attempts
            _updateReputation(p.proposer, -10); // Small penalty for a failed proposal
        }
    }

    // 14. getProposalState(uint256 proposalId)
    function getProposalState(uint224 proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[proposalId];
        if (p.proposer == address(0)) return ProposalState.Pending; // Represents non-existent or initial state
        if (p.executed) return ProposalState.Executed;
        if (block.timestamp <= p.votingEndTime) return ProposalState.Active;
        
        // Voting period has ended, check if it passed or failed
        if (p.yesVotes > p.noVotes && p.yesVotes >= systemParameters[ParamType.GovernanceVoteThreshold]) {
            return ProposalState.Passed;
        } else {
            return ProposalState.Failed;
        }
    }

    // 15. getParamValue(uint8 paramType)
    function getParamValue(uint8 paramType) public view returns (uint256) {
        return systemParameters[ParamType(paramType)];
    }


    // --- IV. Resource Management (AetherDust) ---

    // Internal helper for minting AetherDust
    function _mintDust(address to, uint256 amount) internal {
        require(to != address(0), "AetherForge: Mint to the zero address");
        aetherDustBalances[to] += amount;
        emit AetherDustMinted(to, amount);
        emit AetherDustTransferred(address(0), to, amount); // from address(0) to simulate mint
    }

    // Internal helper for spending/burning AetherDust
    function _spendDust(address from, uint256 amount) internal {
        require(aetherDustBalances[from] >= amount, "AetherForge: Insufficient AetherDust");
        aetherDustBalances[from] -= amount;
        emit AetherDustBurned(from, amount); // Considered spent/burned from user's perspective
        emit AetherDustTransferred(from, address(0), amount); // to address(0) to simulate burn
    }

    // 16. getAetherDustBalance(address account)
    function getAetherDustBalance(address account) public view returns (uint256) {
        return aetherDustBalances[account];
    }

    // 17. distributeAetherDust(address[] memory recipients, uint256[] memory amounts)
    function distributeAetherDust(address[] memory recipients, uint256[] memory amounts)
        public onlyRole(GOVERNOR_ROLE)
    {
        require(recipients.length == amounts.length, "AetherForge: Recipient and amount arrays must match length");
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintDust(recipients[i], amounts[i]);
        }
    }

    // 18. depositNativeCurrencyForDust()
    function depositNativeCurrencyForDust() public payable {
        require(msg.value > 0, "AetherForge: Deposit must be greater than zero");
        // Simplified exchange rate: msg.value * rate / 1 ETH unit
        uint256 dustAmount = msg.value * systemParameters[ParamType.DustToEthRate] / 1 ether; 
        _mintDust(msg.sender, dustAmount);
        _updateReputation(msg.sender, 2); // Small reward for supporting the ecosystem financially
    }

    // 19. withdrawDustForNativeCurrency(uint256 amount)
    function withdrawDustForNativeCurrency(uint256 amount) public hasEnoughDust(amount) {
        // Simplified exchange rate: amount * 1 ETH unit / rate
        uint256 ethAmount = amount * 1 ether / systemParameters[ParamType.DustToEthRate];
        require(address(this).balance >= ethAmount, "AetherForge: Insufficient contract ETH balance for withdrawal");
        
        _spendDust(msg.sender, amount); // Burn AetherDust
        (bool success,) = msg.sender.call{value: ethAmount}(""); // Transfer native currency
        require(success, "AetherForge: ETH withdrawal failed");
        _updateReputation(msg.sender, 2); // Small reward for ecosystem participation
    }

    // --- V. Reputation System ---

    // Internal helper for updating reputation, used by various contract functions
    function _updateReputation(address user, int256 change) internal {
        UserReputation storage rep = userReputations[user];
        int256 currentScore = int256(rep.score);
        currentScore += change;
        if (currentScore < 0) currentScore = 0; // Reputation cannot go below 0
        uint256 oldScore = rep.score;
        rep.score = uint256(currentScore);
        rep.lastActivity = block.timestamp;
        emit ReputationUpdated(user, oldScore, rep.score);
    }

    // 20. updateUserReputation(address user, int256 change)
    function updateUserReputation(address user, int256 change) public onlyRole(GOVERNOR_ROLE) {
        _updateReputation(user, change);
    }

    // 21. getUserReputation(address user)
    function getUserReputation(address user) public view returns (uint256 score, uint256 lastActivity) {
        UserReputation storage rep = userReputations[user];
        return (rep.score, rep.lastActivity);
    }
}

```