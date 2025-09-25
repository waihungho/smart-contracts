Here is a Solidity smart contract for the "Aetherium Garden," a decentralized ecosystem simulator. This contract introduces several advanced, creative, and trendy concepts:

*   **Dynamic NFTs:** Organisms (ERC721-like) have mutable traits and states (growth stage, health, evolution points) that change based on on-chain environmental factors and user interactions.
*   **On-chain Simulation:** A persistent, rule-based simulation of an ecosystem where state variables (environmental factors, organism health/growth) evolve over time and via user input.
*   **Community Governance (DAO-lite):** Users can `proposeEnvironmentalShift` and `voteOnEnvironmentalShift` to influence global game parameters, which are resolved by `resolveEnvironmentalShiftProposal`.
*   **Resource Management Game:** Users manage "Aether" (an ERC20-like token) to cultivate their organisms, feed them, and participate in governance.
*   **Procedural Content Generation (on-chain seed):** `speciesHash` is derived from organism traits, enabling the "discovery" of new, unique species on-chain.
*   **Delegated Access Control:** `delegateCultivation` allows granular permissioning for NFT actions without transferring ownership, enabling collaborative play or "cultivation guilds."
*   **Pseudo-randomness for emergent behavior:** Used for `triggerRandomMutation` and subtle environmental impacts.

To strictly adhere to the "don't duplicate any open source" constraint for the *entire* contract source code, the ERC20-like token for Aether and ERC721-like NFTs for Seeds, Organisms, and Mutagens are implemented directly within the `AetheriumGarden` contract rather than importing external libraries like OpenZeppelin. This makes the entire codebase unique to this project while still adhering to the spirit of those standards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// I. Interfaces (for minimal ERC-like structures for clarity, though implemented internally)
// II. AetheriumGarden Core Contract
//    A. State Variables & Constants
//    B. Events
//    C. Data Structures (EnvironmentalFactors, Organism, Species, Proposal, MutagenType, DelegatePermissions)
//    D. Constructor & Core Modifiers
//    E. Owner-only Management Functions (6 functions)
//    F. Aether Token (ERC20-like) Functions (4 functions)
//    G. Seed & Organism NFT (ERC721-like) Functions (7 functions)
//    H. Ecosystem Dynamics & Discovery Functions (8 functions)
//    I. Delegation & Advanced Interaction Functions (1 function)
//    J. Query & View Functions (4 functions)
//    K. Internal Helper Functions

// Function Summary (Total: 30 distinct functions):
//
// E. Owner-only Management (6 functions):
// 1.  updateEnvironmentalFactor(uint8 _factorIndex, uint256 _newValue): Sets a specific global environmental condition (Temperature, Humidity, SoilFertility, CosmicRadiation).
// 2.  adjustAetherEmissionRate(uint256 _newRate): Modifies the rate at which Aether is minted for rewards or system events.
// 3.  pauseGardenActivity(): Halts all time-sensitive garden dynamics and prevents most user actions.
// 4.  unpauseGardenActivity(): Resumes garden dynamics and user actions.
// 5.  withdrawContractBalance(address _tokenAddress, uint256 _amount): Allows the contract owner to retrieve accidental ERC20 token transfers.
// 6.  createMutagen(address _to, MutagenType _mutagenType): Mints a special Mutagen NFT of a specified type for a user, enabling targeted evolution.
//
// F. Aether Token (ERC20-like) Functions (4 functions):
// 7.  _mintAether(address _to, uint256 _amount): Internal function to mint Aether tokens (used by constructor and system rewards).
// 8.  transferAether(address _to, uint256 _amount): Transfers Aether tokens from the caller's balance to another address.
// 9.  approveAether(address _spender, uint256 _amount): Grants a `_spender` permission to transfer `_amount` of Aether on the caller's behalf.
// 10. transferFromAether(address _from, address _to, uint256 _amount): Transfers Aether from `_from` to `_to` using an existing allowance.
//
// G. Seed & Organism NFT (ERC721-like) Functions (7 functions):
// 11. _mintNFT(address _to, uint256 _tokenId): Internal function to mint a new NFT (Seed, Organism, or Mutagen) and assign ownership.
// 12. mintSeed(address _to): Mints a new Seed NFT to a user, consuming Aether as a planting fee.
// 13. plantSeed(uint256 _seedId): Converts a Seed NFT into an active Organism in the garden, consuming Aether and initializing its state.
// 14. waterOrganism(uint256 _organismId): Feeds an Organism with Aether to boost its health, growth, and prevent decay.
// 15. harvestOrganism(uint256 _organismId): Marks an Organism as inactive, stopping its growth/decay, potentially for sale or processing into other resources.
// 16. evolveOrganism(uint256 _organismId, uint256 _mutagenId): Applies a Mutagen NFT to an Organism, consuming the Mutagen and triggering specific evolutionary changes to its traits.
// 17. transferOrganism(address _from, address _to, uint256 _organismId): Transfers ownership of an Organism (or Seed/Mutagen) NFT.
//
// H. Ecosystem Dynamics & Discovery Functions (8 functions):
// 18. updateOrganismState(uint256 _organismId): Recalculates and updates an Organism's health, growth stage, and evolution points based on elapsed time and current environmental factors. Can be triggered by anyone.
// 19. discoverNewSpecies(uint256 _organismId): Registers an Organism's unique traits as a new Species in the Aetherium Garden, rewarding the discoverer with Aether.
// 20. proposeEnvironmentalShift(uint8 _factorIndex, uint256 _proposedValue, string calldata _justification): Users can propose changes to environmental factors, requiring an Aether stake to prevent spam.
// 21. voteOnEnvironmentalShift(uint256 _proposalId, bool _support): Users vote (support or oppose) on active environmental shift proposals using their Aether stake.
// 22. resolveEnvironmentalShiftProposal(uint256 _proposalId): Finalizes a proposal after its voting period; applies changes if majority and quorum conditions are met, refunding/distributing stakes.
// 23. triggerRandomMutation(uint256 _organismId): Attempts to trigger a random, non-user-controlled mutation in an Organism, influenced by extreme environmental factors or rare events.
// 24. injectAetheriumCatalyst(uint256 _durationBlocks): Owner/privileged function to temporarily boost garden-wide dynamics like organism growth rates or health regeneration.
// 25. claimDiscoveryReward(uint256 _speciesHash): Allows the original discoverer of a specific new species to claim their accumulated Aether reward.
//
// I. Delegation & Advanced Interaction Functions (1 function):
// 26. delegateCultivation(uint256 _organismId, address _delegatee, uint8 _permissionsBitmask): Allows an owner to grant specific cultivation permissions (e.g., watering, evolving) for their organism to another address without transferring full ownership.
//
// J. Query & View Functions (4 functions):
// 27. getOrganismDetails(uint256 _organismId): Retrieves the full current state and attributes of a specific Organism.
// 28. getSpeciesDetails(uint256 _speciesHash): Retrieves details about a discovered Species, including its base traits and discoverer.
// 29. queryEnvironmentalFactors(): Returns the current global environmental conditions (Temperature, Humidity, SoilFertility, CosmicRadiation) as an array.
// 30. getGardenStatistics(): Provides overall statistics for the Aetherium Garden, such as total organisms, Aether supply, and number of discovered species.

contract AetheriumGarden {
    // --- I. State Variables & Constants ---

    address public immutable owner;
    bool public paused;

    // Aether Token (ERC20-like)
    string public constant AETHER_NAME = "Aether";
    string public constant AETHER_SYMBOL = "AET";
    uint8 public constant AETHER_DECIMALS = 18;
    uint256 public totalSupplyAether;
    mapping(address => uint256) public balanceOfAether;
    mapping(address => mapping(address => uint256)) public allowanceAether;
    uint256 public AETHER_REWARD_RATE = 100 * (10 ** AETHER_DECIMALS); // Base reward per discovery

    // NFT (ERC721-like)
    string public constant NFT_NAME = "AetheriumGardenNFT";
    string public constant NFT_SYMBOL = "AGNFT";
    uint256 public nextTokenId; // Universal ID for Seeds, Organisms, Mutagens
    mapping(uint256 => address) public nftOwner;
    mapping(address => uint256) public nftBalance;
    mapping(uint256 => address) public nftApproved; // For a single approved operator

    // Environmental Factors
    // 0: Temperature, 1: Humidity, 2: SoilFertility, 3: CosmicRadiation
    uint256[4] public environmentalFactors; // Current values
    uint256 public constant MAX_FACTOR_VALUE = 1000;
    uint256 public constant MIN_FACTOR_VALUE = 0;

    // Organism Data
    enum GrowthStage { Seedling, Juvenile, Mature, Elder, Dormant }
    struct Organism {
        uint256 id;
        uint256 seedId; // Original Seed NFT ID
        uint256 speciesHash; // Unique identifier for its species
        uint256 generation; // How many times it has evolved
        GrowthStage growthStage;
        uint256 health; // 0-1000
        uint256 evolutionPoints; // Accumulates for evolution attempts
        uint40 lastFedTimestamp; // Use uint40 for timestamp to save gas (up to ~34k years from epoch)
        uint40 lastEvolvedTimestamp;
        uint40 lastStateUpdateTimestamp;
        uint256 traits; // Packed bits for various traits (e.g., color, size, resistance)
        bool isActive; // True if planted and growing, false if harvested/dormant
    }
    mapping(uint256 => Organism) public organisms; // organismId => Organism struct
    mapping(address => uint256[]) public ownerOrganisms; // owner => list of organism IDs (simplistic for demo)

    // Species Data
    struct Species {
        uint256 baseTraitsHash; // The defining traits for this species
        uint40 discoveryTimestamp;
        address discoverer;
        uint256 discoveryGeneration; // Generation of organism when discovered
        uint256 rarityScore; // Calculated based on traits, initial rarity
        uint256 AetherRewardClaimed; // Amount of Aether claimed for discovery
    }
    mapping(uint256 => Species) public discoveredSpecies; // speciesHash => Species struct
    uint256 public totalDiscoveredSpecies;

    // Mutagen Types (NFTs that modify organism traits)
    enum MutagenType { GrowthBoost, TraitShift, HealthRegen, RadiationShield }
    struct Mutagen {
        uint256 id;
        MutagenType mutagenType;
        uint40 mintTimestamp;
    }
    mapping(uint256 => Mutagen) public mutagens; // mutagenId => Mutagen struct

    // Environmental Shift Proposals (DAO-lite)
    struct Proposal {
        uint8 factorIndex;
        uint256 proposedValue;
        uint256 voteFor; // Aether staked for 'yes'
        uint256 voteAgainst; // Aether staked for 'no'
        uint256 proposerStake; // Aether staked by proposer
        address proposer;
        uint40 endTimestamp;
        bool executed;
        string justification;
        mapping(address => bool) hasVoted; // voter => bool
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // 3 days for voting
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 30; // 30% of total Aether supply to pass

    // Delegation for Organism Cultivation
    struct DelegatePermissions {
        address delegatee;
        uint8 permissionsBitmask; // 1: water, 2: evolve, 4: harvest
        uint40 expirationTimestamp;
    }
    mapping(uint256 => DelegatePermissions) public organismDelegates; // organismId => DelegatePermissions

    // Aetherium Catalyst (temporary global boost)
    struct CatalystEffect {
        uint40 activationBlock;
        uint40 endBlock;
        uint256 boostFactor; // e.g., multiplier for growth/health
    }
    CatalystEffect public activeCatalyst;

    // --- II. Events ---

    event AetherTransfer(address indexed from, address indexed to, uint256 amount);
    event AetherApproval(address indexed owner, address indexed spender, uint256 amount);
    event NFTTransfer(address indexed from, address indexed to, uint256 tokenId);
    event NFTApproval(address indexed owner, address indexed approved, uint256 tokenId);

    event EnvironmentalFactorUpdated(uint8 indexed factorIndex, uint256 oldValue, uint256 newValue);
    event SeedMinted(address indexed to, uint256 seedId);
    event OrganismPlanted(address indexed planter, uint256 seedId, uint256 organismId);
    event OrganismStateUpdated(uint256 indexed organismId, GrowthStage newGrowthStage, uint256 newHealth, uint256 newEvolutionPoints);
    event OrganismWatered(uint256 indexed organismId, address indexed feeder, uint256 AetherConsumed);
    event OrganismEvolved(uint256 indexed organismId, uint256 indexed mutagenId, uint256 newSpeciesHash, uint256 newTraits);
    event OrganismHarvested(uint256 indexed organismId, address indexed harvester);
    event SpeciesDiscovered(uint256 indexed speciesHash, address indexed discoverer, uint256 organismId, uint256 rarityScore);
    event MutagenCreated(address indexed to, uint256 mutagenId, MutagenType mutagenType);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 factorIndex, uint256 proposedValue, uint40 endTimestamp);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalResolved(uint256 indexed proposalId, bool executed, uint256 newFactorValue);

    event CultivationDelegated(uint256 indexed organismId, address indexed owner, address indexed delegatee, uint8 permissions);
    event AetheriumCatalystInjected(uint256 boostFactor, uint40 endBlock);
    event DiscoveryRewardClaimed(uint256 indexed speciesHash, address indexed discoverer, uint256 amount);

    // --- III. Data Structures (defined above with state variables) ---

    // --- IV. Constructor & Core Modifiers ---

    constructor() {
        owner = msg.sender;
        paused = false;
        nextTokenId = 1; // Token IDs start from 1
        nextProposalId = 1;

        // Initialize Aether token
        _mintAether(msg.sender, 10_000_000 * (10 ** AETHER_DECIMALS)); // Initial Aether supply

        // Initialize Environmental Factors
        environmentalFactors[0] = 500; // Temperature (mid-range)
        environmentalFactors[1] = 500; // Humidity (mid-range)
        environmentalFactors[2] = 500; // SoilFertility (mid-range)
        environmentalFactors[3] = 100; // CosmicRadiation (low)
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "AG: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "AG: Garden is paused");
        _;
    }

    // --- K. Internal Helper Functions ---

    // Internal ERC20-like transfers
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "AG: Transfer from zero address");
        require(_to != address(0), "AG: Transfer to zero address");
        require(balanceOfAether[_from] >= _amount, "AG: Insufficient Aether balance");

        balanceOfAether[_from] -= _amount;
        balanceOfAether[_to] += _amount;
        emit AetherTransfer(_from, _to, _amount);
    }

    // Internal ERC721-like transfers
    function _transferNFT(address _from, address _to, uint256 _tokenId) internal {
        require(_from != address(0), "AG: NFT transfer from zero address");
        require(_to != address(0), "AG: NFT transfer to zero address");
        require(nftOwner[_tokenId] == _from, "AG: Not NFT owner");
        require(nftBalance[_from] > 0, "AG: Sender has no NFTs"); // Safety check

        _clearApproval(_tokenId);
        nftBalance[_from]--;
        nftOwner[_tokenId] = _to;
        nftBalance[_to]++;
        emit NFTTransfer(_from, _to, _tokenId);
    }

    function _approveNFT(address _to, uint256 _tokenId) internal {
        nftApproved[_tokenId] = _to;
        emit NFTApproval(nftOwner[_tokenId], _to, _tokenId);
    }

    function _clearApproval(uint256 _tokenId) internal {
        if (nftApproved[_tokenId] != address(0)) {
            nftApproved[_tokenId] = address(0);
        }
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address _owner = nftOwner[_tokenId];
        return (_spender == _owner || _spender == nftApproved[_tokenId]);
    }

    // Pseudo-random number generator (for demonstration, not cryptographically secure)
    function _getDynamicRandomness(uint256 _seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, _seed, msg.sender)));
    }

    // Updates organism health/growth based on time and environment
    function _calculateAndUpdateOrganismDynamics(uint256 _organismId) internal {
        Organism storage organism = organisms[_organismId];
        require(organism.id != 0, "AG: Organism does not exist");
        if (!organism.isActive) return; // Only active organisms grow/decay

        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - organism.lastStateUpdateTimestamp;
        if (timeElapsed == 0) return; // No time passed, no update needed

        // Apply catalyst effect if active
        uint256 currentBoostFactor = 1;
        if (activeCatalyst.endBlock > 0 && block.number >= activeCatalyst.activationBlock && block.number <= activeCatalyst.endBlock) {
            currentBoostFactor = activeCatalyst.boostFactor;
        }

        // Health decay and growth
        uint256 healthDecayRate = 1; // Base decay per unit time
        uint256 growthRate = 1;      // Base growth per unit time

        // Environmental impact on health and growth (simplified)
        // Example: Extreme temperature reduces health, good soil boosts growth
        if (environmentalFactors[0] > 700 || environmentalFactors[0] < 300) healthDecayRate += 1; // High/Low Temp
        if (environmentalFactors[2] > 700) growthRate += 1; // High Soil Fertility

        // Calculate health changes
        uint256 healthChange = timeElapsed * healthDecayRate;
        if (organism.health > healthChange) {
            organism.health -= healthChange;
        } else {
            organism.health = 0;
            organism.isActive = false; // Organism dies if health hits 0
            emit OrganismHarvested(_organismId, nftOwner[_organismId]); // Treat as 'harvested' if it dies
        }

        // Calculate evolution points and growth stage
        if (organism.health > 200) { // Only grow if healthy
            uint256 pointsGained = (timeElapsed * growthRate * currentBoostFactor) / 1000; // Scale points
            organism.evolutionPoints += pointsGained;

            // Simple growth stage progression
            if (organism.growthStage == GrowthStage.Seedling && organism.evolutionPoints >= 1000) {
                organism.growthStage = GrowthStage.Juvenile;
            } else if (organism.growthStage == GrowthStage.Juvenile && organism.evolutionPoints >= 3000) {
                organism.growthStage = GrowthStage.Mature;
            } else if (organism.growthStage == GrowthStage.Mature && organism.evolutionPoints >= 6000) {
                organism.growthStage = GrowthStage.Elder;
            }
        }

        organism.lastStateUpdateTimestamp = currentTime;
        emit OrganismStateUpdated(organism.id, organism.growthStage, organism.health, organism.evolutionPoints);
    }

    // --- E. Owner-only Management Functions (6 functions) ---

    // 1. Sets a specific global environmental condition.
    function updateEnvironmentalFactor(uint8 _factorIndex, uint256 _newValue) external onlyOwner {
        require(_factorIndex < 4, "AG: Invalid factor index");
        require(_newValue <= MAX_FACTOR_VALUE, "AG: Factor value too high");
        require(_newValue >= MIN_FACTOR_VALUE, "AG: Factor value too low");
        uint256 oldValue = environmentalFactors[_factorIndex];
        environmentalFactors[_factorIndex] = _newValue;
        emit EnvironmentalFactorUpdated(_factorIndex, oldValue, _newValue);
    }

    // 2. Modifies the rate at which Aether is minted for rewards or system events.
    function adjustAetherEmissionRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "AG: Rate must be positive");
        AETHER_REWARD_RATE = _newRate;
    }

    // 3. Halts all time-sensitive garden dynamics and prevents most user actions.
    function pauseGardenActivity() external onlyOwner {
        paused = true;
    }

    // 4. Resumes garden dynamics and user actions.
    function unpauseGardenActivity() external onlyOwner {
        paused = false;
    }

    // 5. Allows the contract owner to retrieve accidental ERC20 token transfers.
    function withdrawContractBalance(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0)) { // ETH
            require(address(this).balance >= _amount, "AG: Insufficient ETH balance");
            payable(owner).transfer(_amount);
        } else if (_tokenAddress == address(this)) { // Aether
            _transfer(address(this), owner, _amount);
        } else { // Other ERC20
            // Simplified for demonstration: assumes IERC20 is available
            // In a real scenario, you'd need an IERC20 interface and safeTransfer
            (bool success, bytes memory data) = _tokenAddress.call(abi.encodeWithSelector(0xa9059cbb, owner, _amount));
            require(success, "AG: Token transfer failed");
        }
    }

    // 6. Mints a special Mutagen NFT of a specified type for a user, enabling targeted evolution.
    function createMutagen(address _to, MutagenType _mutagenType) external onlyOwner whenNotPaused returns (uint256) {
        require(_to != address(0), "AG: Cannot mint to zero address");
        uint256 newMutagenId = nextTokenId++;
        _mintNFT(_to, newMutagenId);
        mutagens[newMutagenId] = Mutagen({
            id: newMutagenId,
            mutagenType: _mutagenType,
            mintTimestamp: uint40(block.timestamp)
        });
        emit MutagenCreated(_to, newMutagenId, _mutagenType);
        return newMutagenId;
    }

    // --- F. Aether Token (ERC20-like) Functions (4 functions) ---

    // 7. Internal function to mint Aether tokens (used by constructor and system rewards).
    function _mintAether(address _to, uint256 _amount) internal {
        require(_to != address(0), "AG: Cannot mint to zero address");
        totalSupplyAether += _amount;
        balanceOfAether[_to] += _amount;
        emit AetherTransfer(address(0), _to, _amount);
    }

    // 8. Transfers Aether tokens from caller to another address.
    function transferAether(address _to, uint256 _amount) external whenNotPaused returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    // 9. Grants a `_spender` permission to transfer `_amount` of Aether on the caller's behalf.
    function approveAether(address _spender, uint256 _amount) external whenNotPaused returns (bool) {
        allowanceAether[msg.sender][_spender] = _amount;
        emit AetherApproval(msg.sender, _spender, _amount);
        return true;
    }

    // 10. Transfers Aether from one address to another using an existing allowance.
    function transferFromAether(address _from, address _to, uint256 _amount) external whenNotPaused returns (bool) {
        require(allowanceAether[_from][msg.sender] >= _amount, "AG: Insufficient Aether allowance");
        allowanceAether[_from][msg.sender] -= _amount;
        _transfer(_from, _to, _amount);
        return true;
    }

    // --- G. Seed & Organism NFT (ERC721-like) Functions (7 functions) ---

    // 11. Internal function to mint a new NFT (Seed, Organism, or Mutagen) and assign ownership.
    function _mintNFT(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "AG: Cannot mint NFT to zero address");
        require(nftOwner[_tokenId] == address(0), "AG: Token ID already exists"); // Ensure unique ID
        nftOwner[_tokenId] = _to;
        nftBalance[_to]++;
        emit NFTTransfer(address(0), _to, _tokenId);
    }

    // 12. Mints a new Seed NFT to a user, consuming Aether as a planting fee.
    function mintSeed(address _to) external whenNotPaused returns (uint256) {
        require(_to != address(0), "AG: Cannot mint seed to zero address");
        uint256 seedCost = 100 * (10 ** AETHER_DECIMALS); // Example cost
        _transfer(msg.sender, address(this), seedCost); // Burn/collect Aether
        
        uint256 newSeedId = nextTokenId++;
        _mintNFT(_to, newSeedId);
        // Seeds are initially just NFTs, not organisms yet
        emit SeedMinted(_to, newSeedId);
        return newSeedId;
    }

    // 13. Converts a Seed NFT into an active Organism in the garden, consuming Aether and initializing its state.
    function plantSeed(uint256 _seedId) external whenNotPaused {
        require(nftOwner[_seedId] == msg.sender, "AG: Not owner of this seed");
        require(organisms[_seedId].id == 0, "AG: This seed is already planted as an organism"); // Ensure not already planted

        uint256 plantingFee = 50 * (10 ** AETHER_DECIMALS); // Example planting fee
        _transfer(msg.sender, address(this), plantingFee); // Burn/collect Aether

        // Seed becomes an Organism, ID remains the same
        Organism storage newOrganism = organisms[_seedId];
        newOrganism.id = _seedId;
        newOrganism.seedId = _seedId;
        newOrganism.generation = 0;
        newOrganism.growthStage = GrowthStage.Seedling;
        newOrganism.health = 1000; // Full health
        newOrganism.evolutionPoints = 0;
        newOrganism.lastFedTimestamp = uint40(block.timestamp);
        newOrganism.lastEvolvedTimestamp = uint40(block.timestamp);
        newOrganism.lastStateUpdateTimestamp = uint40(block.timestamp);
        newOrganism.traits = _getDynamicRandomness(_seedId) % (2**32); // Initial random traits
        newOrganism.speciesHash = newOrganism.traits; // Initial species hash is just its traits
        newOrganism.isActive = true;

        ownerOrganisms[msg.sender].push(_seedId);
        emit OrganismPlanted(msg.sender, _seedId, _seedId); // _seedId is now organismId
    }

    // 14. Feeds an Organism with Aether to boost its health, growth, and prevent decay.
    function waterOrganism(uint256 _organismId) external whenNotPaused {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        require(organisms[_organismId].isActive, "AG: Organism is not active");
        require(nftOwner[_organismId] == msg.sender || _isApprovedOrOwner(msg.sender, _organismId) || _hasDelegatePermission(_organismId, msg.sender, 1), "AG: Not authorized to water");

        uint256 AetherCost = 10 * (10 ** AETHER_DECIMALS); // Example cost
        _transfer(msg.sender, address(this), AetherCost);

        _calculateAndUpdateOrganismDynamics(_organismId); // Update state before watering
        organisms[_organismId].health += 200; // Boost health
        if (organisms[_organismId].health > 1000) organisms[_organismId].health = 1000;
        organisms[_organismId].lastFedTimestamp = uint40(block.timestamp);

        emit OrganismWatered(_organismId, msg.sender, AetherCost);
    }

    // 15. Marks an Organism as inactive, stopping its growth/decay, potentially for sale or processing into other resources.
    function harvestOrganism(uint256 _organismId) external whenNotPaused {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        require(organisms[_organismId].isActive, "AG: Organism is already harvested or dormant");
        require(nftOwner[_organismId] == msg.sender || _isApprovedOrOwner(msg.sender, _organismId) || _hasDelegatePermission(_organismId, msg.sender, 4), "AG: Not authorized to harvest");

        _calculateAndUpdateOrganismDynamics(_organismId); // Final state update
        organisms[_organismId].isActive = false;
        organisms[_organismId].growthStage = GrowthStage.Dormant; // Mark as dormant
        emit OrganismHarvested(_organismId, msg.sender);
    }

    // 16. Applies a Mutagen NFT to an Organism, consuming the Mutagen and triggering specific evolutionary changes to its traits.
    function evolveOrganism(uint256 _organismId, uint256 _mutagenId) external whenNotPaused {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        require(organisms[_organismId].isActive, "AG: Organism is not active");
        require(nftOwner[_organismId] == msg.sender || _isApprovedOrOwner(msg.sender, _organismId) || _hasDelegatePermission(_organismId, msg.sender, 2), "AG: Not authorized to evolve organism");
        require(mutagens[_mutagenId].id != 0, "AG: Mutagen does not exist");
        require(nftOwner[_mutagenId] == msg.sender, "AG: Not owner of this mutagen");

        _calculateAndUpdateOrganismDynamics(_organismId); // Update organism state
        
        // Apply mutagen effect (simplified)
        // This is where complex trait modification logic would go based on MutagenType
        if (mutagens[_mutagenId].mutagenType == MutagenType.TraitShift) {
             organisms[_organismId].traits = _getDynamicRandomness(_organismId + _mutagenId) % (2**32); // Random trait shift
        } else if (mutagens[_mutagenId].mutagenType == MutagenType.GrowthBoost) {
            organisms[_organismId].evolutionPoints += 500; // Boost evolution points
        }
        // ... other mutagen effects

        organisms[_organismId].generation++;
        organisms[_organismId].lastEvolvedTimestamp = uint40(block.timestamp);
        organisms[_organismId].speciesHash = keccak256(abi.encodePacked(organisms[_organismId].traits)); // New species hash based on new traits

        // Burn the mutagen
        _transferNFT(msg.sender, address(0), _mutagenId); // Transfer to zero address to "burn"
        delete mutagens[_mutagenId];

        emit OrganismEvolved(_organismId, _mutagenId, organisms[_organismId].speciesHash, organisms[_organismId].traits);
    }

    // 17. Transfers ownership of an Organism (or Seed/Mutagen) NFT.
    function transferOrganism(address _from, address _to, uint256 _organismId) external whenNotPaused {
        require(nftOwner[_organismId] == msg.sender || nftApproved[_organismId] == msg.sender, "AG: Not authorized to transfer NFT");
        require(_from == nftOwner[_organismId], "AG: From address does not own this NFT");

        _transferNFT(_from, _to, _organismId); // Handles clearing approval
        // Update ownerOrganisms mapping (simplified, requires iteration for removal from old owner)
        // For actual implementation, consider linked lists or more complex mapping
    }

    // --- H. Ecosystem Dynamics & Discovery Functions (8 functions) ---

    // 18. Recalculates and updates an Organism's health, growth stage, and evolution points based on elapsed time and environment.
    function updateOrganismState(uint256 _organismId) external whenNotPaused {
        _calculateAndUpdateOrganismDynamics(_organismId);
    }

    // 19. Registers an Organism's unique traits as a new Species in the Aetherium Garden, rewarding the discoverer with Aether.
    function discoverNewSpecies(uint256 _organismId) external whenNotPaused {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        require(nftOwner[_organismId] == msg.sender, "AG: Only owner can discover species from their organism");

        // Ensure organism state is up-to-date
        _calculateAndUpdateOrganismDynamics(_organismId);

        uint256 currentSpeciesHash = organisms[_organismId].speciesHash;
        require(discoveredSpecies[currentSpeciesHash].discoveryTimestamp == 0, "AG: Species already discovered");

        // Simple rarity calculation (can be much more complex)
        uint256 rarity = (organisms[_organismId].traits % 100) + 1; // 1-100 based on traits

        discoveredSpecies[currentSpeciesHash] = Species({
            baseTraitsHash: organisms[_organismId].traits,
            discoveryTimestamp: uint40(block.timestamp),
            discoverer: msg.sender,
            discoveryGeneration: organisms[_organismId].generation,
            rarityScore: rarity,
            AetherRewardClaimed: 0
        });
        totalDiscoveredSpecies++;

        emit SpeciesDiscovered(currentSpeciesHash, msg.sender, _organismId, rarity);
    }

    // 20. Users can propose changes to environmental factors, requiring an Aether stake to prevent spam.
    function proposeEnvironmentalShift(uint8 _factorIndex, uint256 _proposedValue, string calldata _justification) external whenNotPaused {
        require(_factorIndex < 4, "AG: Invalid factor index");
        require(_proposedValue <= MAX_FACTOR_VALUE, "AG: Proposed value too high");
        require(_proposedValue >= MIN_FACTOR_VALUE, "AG: Proposed value too low");
        require(bytes(_justification).length > 0, "AG: Justification required");

        uint256 proposalStake = 500 * (10 ** AETHER_DECIMALS); // Example stake
        _transfer(msg.sender, address(this), proposalStake); // Proposer stakes Aether

        uint256 id = nextProposalId++;
        proposals[id] = Proposal({
            factorIndex: _factorIndex,
            proposedValue: _proposedValue,
            voteFor: 0,
            voteAgainst: 0,
            proposerStake: proposalStake,
            proposer: msg.sender,
            endTimestamp: uint40(block.timestamp) + uint40(PROPOSAL_VOTING_PERIOD),
            executed: false,
            justification: _justification,
            hasVoted: new mapping(address => bool) // Initialize empty
        });

        emit ProposalCreated(id, msg.sender, _factorIndex, _proposedValue, proposals[id].endTimestamp);
    }

    // 21. Users vote (support or oppose) on active environmental shift proposals using their Aether stake.
    function voteOnEnvironmentalShift(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "AG: Proposal does not exist");
        require(block.timestamp < proposal.endTimestamp, "AG: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AG: Already voted on this proposal");

        uint256 voterAetherBalance = balanceOfAether[msg.sender];
        require(voterAetherBalance > 0, "AG: Voter must hold Aether");

        if (_support) {
            proposal.voteFor += voterAetherBalance;
        } else {
            proposal.voteAgainst += voterAetherBalance;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterAetherBalance);
    }

    // 22. Finalizes a proposal after its voting period; applies changes if majority and quorum conditions are met, refunding/distributing stakes.
    function resolveEnvironmentalShiftProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "AG: Proposal does not exist");
        require(block.timestamp >= proposal.endTimestamp, "AG: Voting period not yet ended");
        require(!proposal.executed, "AG: Proposal already executed");

        proposal.executed = true; // Mark as executed regardless of outcome

        uint256 totalVotes = proposal.voteFor + proposal.voteAgainst;
        bool quorumMet = (totalVotes * 100 / totalSupplyAether) >= PROPOSAL_QUORUM_PERCENT;
        bool passed = quorumMet && (proposal.voteFor > proposal.voteAgainst);

        if (passed) {
            uint256 oldValue = environmentalFactors[proposal.factorIndex];
            environmentalFactors[proposal.factorIndex] = proposal.proposedValue;
            // Refund proposer's stake
            _transfer(address(this), proposal.proposer, proposal.proposerStake);
            emit EnvironmentalFactorUpdated(proposal.factorIndex, oldValue, proposal.proposedValue);
            emit ProposalResolved(_proposalId, true, proposal.proposedValue);
        } else {
            // Proposer loses stake if proposal fails (or distribute to voters, etc.)
            // For simplicity, stake is kept by contract if fails.
            emit ProposalResolved(_proposalId, false, environmentalFactors[proposal.factorIndex]);
        }
    }

    // 23. Attempts to trigger a random, non-user-controlled mutation in an Organism based on environmental factors.
    function triggerRandomMutation(uint256 _organismId) external whenNotPaused {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        require(organisms[_organismId].isActive, "AG: Organism is not active");

        _calculateAndUpdateOrganismDynamics(_organismId); // Update state first

        // Very low chance of mutation, potentially influenced by CosmicRadiation
        uint256 mutationChance = environmentalFactors[3]; // Cosmic Radiation level
        uint256 randomRoll = _getDynamicRandomness(_organismId) % 1000; // 0-999

        if (randomRoll < mutationChance) { // E.g., if radiation is 100, 10% chance
            organisms[_organismId].traits = _getDynamicRandomness(_organismId + block.timestamp) % (2**32); // Random trait shift
            organisms[_organismId].generation++;
            organisms[_organismId].speciesHash = keccak256(abi.encodePacked(organisms[_organismId].traits));
            emit OrganismEvolved(_organismId, 0, organisms[_organismId].speciesHash, organisms[_organismId].traits); // MutagenId 0 for natural mutation
        }
    }

    // 24. Owner/privileged function to temporarily boost garden-wide dynamics like growth rates or health regeneration.
    function injectAetheriumCatalyst(uint256 _boostFactor, uint256 _durationBlocks) external onlyOwner {
        require(_boostFactor > 1, "AG: Boost factor must be greater than 1");
        require(_durationBlocks > 0, "AG: Duration must be positive");
        activeCatalyst = CatalystEffect({
            activationBlock: uint40(block.number),
            endBlock: uint40(block.number + _durationBlocks),
            boostFactor: _boostFactor
        });
        emit AetheriumCatalystInjected(_boostFactor, activeCatalyst.endBlock);
    }

    // 25. Allows the original discoverer of a specific new species to claim their accumulated Aether reward.
    function claimDiscoveryReward(uint256 _speciesHash) external whenNotPaused {
        Species storage species = discoveredSpecies[_speciesHash];
        require(species.discoverer == msg.sender, "AG: Not the discoverer of this species");
        require(species.AetherRewardClaimed == 0, "AG: Reward already claimed"); // Only one claim per species

        uint256 rewardAmount = AETHER_REWARD_RATE * species.rarityScore; // Example: higher rarity, higher reward
        _mintAether(msg.sender, rewardAmount); // Mint Aether as reward
        species.AetherRewardClaimed = rewardAmount;

        emit DiscoveryRewardClaimed(_speciesHash, msg.sender, rewardAmount);
    }

    // --- I. Delegation & Advanced Interaction Functions (1 function) ---

    // Internal helper for delegate permissions
    function _hasDelegatePermission(uint256 _organismId, address _delegatee, uint8 _requiredPermission) internal view returns (bool) {
        DelegatePermissions storage delegateInfo = organismDelegates[_organismId];
        if (delegateInfo.delegatee != _delegatee) return false;
        if (delegateInfo.expirationTimestamp < block.timestamp) return false;
        return (delegateInfo.permissionsBitmask & _requiredPermission) == _requiredPermission;
    }

    // 26. Allows an owner to grant specific cultivation permissions (e.g., watering, evolving) for their organism to another address without transferring full ownership.
    // _permissionsBitmask: 1 (water), 2 (evolve), 4 (harvest)
    function delegateCultivation(uint256 _organismId, address _delegatee, uint8 _permissionsBitmask) external whenNotPaused {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        require(nftOwner[_organismId] == msg.sender, "AG: Only owner can delegate");
        require(_delegatee != address(0), "AG: Cannot delegate to zero address");
        require(_permissionsBitmask > 0 && _permissionsBitmask < 8, "AG: Invalid permissions bitmask"); // Max 1+2+4=7

        organismDelegates[_organismId] = DelegatePermissions({
            delegatee: _delegatee,
            permissionsBitmask: _permissionsBitmask,
            expirationTimestamp: uint40(block.timestamp + 30 days) // Delegation lasts 30 days
        });

        emit CultivationDelegated(_organismId, msg.sender, _delegatee, _permissionsBitmask);
    }

    // --- J. Query & View Functions (4 functions) ---

    // 27. Retrieves the full current state and attributes of a specific Organism.
    function getOrganismDetails(uint256 _organismId) external view returns (Organism memory) {
        require(organisms[_organismId].id != 0, "AG: Organism does not exist");
        return organisms[_organismId];
    }

    // 28. Retrieves details about a discovered Species, including its base traits and discoverer.
    function getSpeciesDetails(uint256 _speciesHash) external view returns (Species memory) {
        require(discoveredSpecies[_speciesHash].discoveryTimestamp != 0, "AG: Species not discovered");
        return discoveredSpecies[_speciesHash];
    }

    // 29. Returns the current global environmental conditions (Temperature, Humidity, SoilFertility, CosmicRadiation) as an array.
    function queryEnvironmentalFactors() external view returns (uint256[4] memory) {
        return environmentalFactors;
    }

    // 30. Provides overall statistics for the Aetherium Garden (total organisms, Aether supply, discovered species count).
    function getGardenStatistics() external view returns (uint256 totalNFTs, uint256 currentAetherSupply, uint256 totalSpecies) {
        return (nextTokenId - 1, totalSupplyAether, totalDiscoveredSpecies);
    }

    // Helper to get owner's organisms (simple array for demo, inefficient for many NFTs)
    function getOwnerOrganisms(address _owner) external view returns (uint256[] memory) {
        return ownerOrganisms[_owner];
    }

    // ERC20-like view functions
    function getAetherBalance(address account) external view returns (uint256) {
        return balanceOfAether[account];
    }
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowanceAether[_owner][_spender];
    }

    // ERC721-like view functions
    function ownerOfNFT(uint256 _tokenId) external view returns (address) {
        require(nftOwner[_tokenId] != address(0), "AG: Invalid token ID");
        return nftOwner[_tokenId];
    }
    function balanceOfNFT(address _owner) external view returns (uint256) {
        return nftBalance[_owner];
    }
    function getApprovedNFT(uint256 _tokenId) external view returns (address) {
        require(nftOwner[_tokenId] != address(0), "AG: Invalid token ID");
        return nftApproved[_tokenId];
    }
}
```