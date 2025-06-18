Okay, here is a Solidity smart contract concept for an "Ethereal Blooms: Decentralized Garden" simulation. This contract combines elements of dynamic NFTs (Plots containing dynamic Blooms), on-chain simulation, resource management (Gardener Energy, Nutrient Pool), community interaction (Observation, Endorsement), and parameter-based evolution.

It aims to be creative and advanced by having complex state managed on-chain for Blooms and Plots, using time-based mechanics for growth/decay, simulating environmental effects, implementing a cross-pollination mechanism, and incorporating a user energy system for actions.

This contract is designed for demonstration and educational purposes. A production version would require extensive optimization, gas considerations, security audits, and potentially external oracle integration for more complex environmental factors.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For basic math operations

// --- Contract Outline and Function Summary ---
//
// Contract Name: EtherealBloomsGarden
// Description: A decentralized garden simulation where users own plots (NFTs)
//              and cultivate dynamic, evolving blooms within them. Blooms
//              grow, decay, and can be cross-pollinated based on time, user
//              interactions, environmental parameters, and inherent traits.
//              Includes resource management (Gardener Energy, Nutrient Pool)
//              and community elements (Observation, Endorsement, Reputation).
//
// Inherits: ERC721 (for Plot ownership), Ownable
//
// Core Concepts:
// - Plots (ERC721 Tokens): Represents ownership of a garden area. Can hold multiple Blooms.
// - Blooms (Structs): Dynamic entities within Plots. Have traits, growth stage, resilience, etc.
//   - Blooms evolve based on time (blocks), user actions (Nurture), and environment.
//   - Can be harvested or pruned.
//   - Can participate in Cross-Pollination to potentially create new Blooms.
// - Gardener Energy: Per-user resource consumed by actions like Planting, Nurturing, Pollinating.
//   - Refills automatically over time (blocks).
// - Nutrient Pool: Shared pool (funded by deposits or action costs) used conceptually
//   for Bloom growth and potentially future features.
// - Environmental Parameters: Global settings controlled by owner/DAO that affect Bloom health/growth.
// - Reputation: User score increased by observing/endorsing gardens.
//
// Function Categories:
// 1. ERC721 Core (Standard): balance, ownerOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom. (8 functions)
// 2. Plot Management: mintPlot (admin), setPlotName, getPlotDetails, getUserGardens, getBloomsOnPlot. (5 functions)
// 3. Bloom Management & Interaction: plantBloom, nurtureBloom, crossPollinate, harvestBloom, pruneBloom, getBloomDetails. (6 functions)
// 4. Simulation & State: updateBloomState (internal logic), getBloomCount, getPlotCount. (3 functions - 1 internal, 2 view)
// 5. Gardener Energy System: getUserGardenerEnergy, setGardenerEnergyParams (admin), _spendGardenerEnergy (internal), _replenishGardenerEnergy (internal), getTotalGardenerEnergySupply (view). (5 functions - 2 internal, 3 public/view)
// 6. Nutrient Pool: depositIntoNutrientPool (payable), withdrawFromNutrientPool (admin). (2 functions)
// 7. Community & Reputation: observeGarden, endorseGarden, getUserReputation. (3 functions)
// 8. Environment Management: setEnvironmentalParameter (admin), getEnvironmentalParameters. (2 functions)
// 9. Configuration: setBloomTypeParameters (admin). (1 function)
// 10. Utility/View: getContractStateSummary. (1 function)
//
// Total External/Public Functions: ~8 (ERC721) + 5 + 6 + 2 + 3 + 2 + 3 + 2 + 1 + 1 = ~33 functions. (Well over 20 required)
//
// Note: This contract is a complex simulation. Gas costs for interactions involving Bloom state updates (_updateBloomState, crossPollinate)
// could be significant depending on the complexity of the logic implemented. State variables are packed where possible but extensive state storage
// is inherent in a simulation like this. Error handling and edge cases are simplified for clarity.

contract EtherealBloomsGarden is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256; // For min/max, clamp if needed (basic arithmetic is fine here)

    // --- Structs ---

    struct Bloom {
        uint256 bloomId;
        uint256 plotId;
        uint8 bloomTypeId; // Link to BloomType config
        uint8 growthStage; // 0-100
        uint8 resilience;  // 0-100 (resistance to decay/environment)
        uint8 etherAffinity; // 0-100 (attraction to nutrient pool/ether, maybe affects cross-pollination)
        uint48 lastInteractionBlock; // Block number of last nurture/action
        uint48 plantedBlock; // Block number when planted
        address owner; // Owner of the plot at planting time (snapshot)
        bool exists; // Flag to check if bloom is active/not harvested
    }

    struct BloomType {
        string name;
        uint8 baseResilience;
        uint8 baseEtherAffinity;
        uint8 growthRate; // How fast it grows per interaction/time
        uint8 decayRate; // How fast it decays per time if neglected
        bool canCrossPollinate;
    }

    struct Plot {
        uint256 tokenId; // Same as the ERC721 token ID
        string name;
        uint256[] bloomIds; // List of bloom IDs currently on this plot
        uint48 lastObservedBlock; // For potential passive reputation/energy mechanics
    }

    // --- Enums ---

    enum GrowthStage { Seedling, Sprouting, Budding, Flowering, Mature, Wilting, Decayed }
    enum EnvironmentParameter { SunshineIntensity, RainfallAmount, EtherDensity }

    // --- State Variables ---

    Counters.Counter private _plotTokenIds;
    Counters.Counter private _bloomIds;

    mapping(uint256 => Plot) public plots; // tokenId => Plot data
    mapping(uint256 => Bloom) public blooms; // bloomId => Bloom data
    mapping(uint8 => BloomType) public bloomTypes; // bloomTypeId => BloomType config

    mapping(address => uint256) public userReputation; // User address => Reputation score
    mapping(address => uint256) private _userGardenerEnergy; // User address => Current Gardener Energy
    mapping(address => uint48) private _lastEnergyReplenishBlock; // User address => Last block energy was replenished

    uint256 public constant MAX_GROWTH_STAGE = 100;
    uint256 public constant MAX_RESILIENCE = 100;
    uint256 public constant MAX_ETHER_AFFINITY = 100;
    uint256 public constant MAX_GARDENER_ENERGY = 1000;
    uint256 public constant ENERGY_REPLENISH_PER_BLOCK = 5; // How much energy replenishes per block

    // Action Costs (Gardener Energy)
    uint256 public COST_PLANT_BLOOM = 100;
    uint256 public COST_NURTURE_BLOOM = 50;
    uint256 public COST_CROSS_POLLINATE = 150;
    uint256 public COST_HARVEST_BLOOM = 20; // Costs energy to harvest? Or yields energy? Let's make it cost.
    uint256 public COST_PRUNE_BLOOM = 10;

    // Nutrient Pool (Funded by ETH deposits)
    uint256 public nutrientPoolBalance;

    // Environmental Parameters (Defaults)
    mapping(uint8 => uint8) public environmentalParameters; // EnvParameter(uint8) => value (0-100)

    uint256 public constant REP_OBSERVE_PLOT = 5;
    uint256 public constant REP_ENDORSE_PLOT = 20;

    // --- Events ---

    event PlotMinted(address indexed owner, uint256 indexed tokenId);
    event PlotNameChanged(uint256 indexed tokenId, string newName);
    event BloomPlanted(uint256 indexed plotId, uint256 indexed bloomId, uint8 indexed bloomTypeId);
    event BloomNurtured(uint256 indexed bloomId, address indexed nurturer, uint8 newGrowthStage);
    event BloomHarvested(uint256 indexed bloomId, address indexed harvester);
    event BloomPruned(uint256 indexed bloomId, address indexed pruner);
    event BloomsCrossPollinated(uint256 indexed parent1BloomId, uint256 indexed parent2BloomId, uint256 indexed newBloomId);
    event GardenObserved(uint256 indexed plotId, address indexed observer, uint256 reputationGained);
    event GardenEndorsed(uint256 indexed plotId, address indexed endorser, uint256 reputationGained);
    event GardenerEnergySpent(address indexed user, uint256 amount, uint256 remaining);
    event NutrientPoolDeposited(address indexed user, uint256 amount);
    event NutrientPoolWithdrawal(address indexed recipient, uint256 amount);
    event EnvironmentParameterChanged(EnvironmentParameter indexed paramType, uint8 newValue);
    event BloomTypeCreatedOrUpdated(uint8 indexed bloomTypeId, string name);

    // --- Modifiers ---

    modifier plotExists(uint256 _plotId) {
        require(_exists(_plotId), "EBG: Plot does not exist");
        _;
    }

    modifier bloomExists(uint256 _bloomId) {
        require(blooms[_bloomId].exists, "EBG: Bloom does not exist or is harvested");
        _;
    }

    modifier hasGardenerEnergy(uint256 _requiredEnergy) {
        _replenishGardenerEnergy(msg.sender); // Replenish energy before check
        require(_userGardenerEnergy[msg.sender] >= _requiredEnergy, "EBG: Insufficient Gardener Energy");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("Ethereal Blooms Garden Plot", "EBG") Ownable(msg.sender) {
        // Set default environmental parameters
        environmentalParameters[uint8(EnvironmentParameter.SunshineIntensity)] = 70;
        environmentalParameters[uint8(EnvironmentParameter.RainfallAmount)] = 50;
        environmentalParameters[uint8(EnvironmentParameter.EtherDensity)] = 60;
    }

    // --- ERC721 Core Implementations (Required Overrides) ---

    // The base ERC721 contract from OpenZeppelin provides these implementations
    // but it's good practice to list them conceptually as part of the function count.
    // We don't need to write the code here if using the standard library.
    // uint256 public override func balanceOf(address owner);
    // address public override func ownerOf(uint256 tokenId);
    // address public override func getApproved(uint256 tokenId);
    // bool public override func isApprovedForAll(address owner, address operator);
    // function approve(address to, uint256 tokenId) public override;
    // function setApprovalForAll(address operator, bool approved) public override;
    // function transferFrom(address from, address to, uint256 tokenId) public override;
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override;
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override;

    // Override _update used by ERC721 transfers to clean up plot-bloom links if needed
    // For this design, blooms stay with the plot regardless of owner change.
    // We'll track original planter/owner on the Bloom struct.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = ERC721._ownerOf(tokenId);
        super._update(to, tokenId, auth); // Call the parent update logic

        if (from != address(0) && to == address(0)) {
            // Plot is being burned. Decide what happens to blooms.
            // Option 1: Burn Blooms with the plot.
            // Option 2: Leave Blooms as orphaned (more complex state management).
            // Let's choose Option 1 for simplicity in this demo.
            Plot storage plot = plots[tokenId];
            for (uint256 i = 0; i < plot.bloomIds.length; i++) {
                uint256 bloomIdToPrune = plot.bloomIds[i];
                if (blooms[bloomIdToPrune].exists) {
                    _pruneBloomInternal(bloomIdToPrune); // Internal prune logic
                }
            }
            delete plots[tokenId]; // Clean up plot data
        }

        return to;
    }


    // --- Plot Management ---

    /// @notice Allows owner to mint a new plot NFT.
    /// @param _to The address to mint the plot to.
    function mintPlot(address _to) public onlyOwner {
        _plotTokenIds.increment();
        uint256 newTokenId = _plotTokenIds.current();
        _safeMint(_to, newTokenId);

        plots[newTokenId].tokenId = newTokenId;
        // Name and bloomIds are empty by default
        plots[newTokenId].lastObservedBlock = uint48(block.number); // Initialize observation time

        emit PlotMinted(_to, newTokenId);
    }

    /// @notice Allows plot owner to set a name for their garden plot.
    /// @param _plotId The ID of the plot.
    /// @param _name The new name for the plot.
    function setPlotName(uint256 _plotId, string memory _name) public plotExists(_plotId) {
        require(_isApprovedOrOwner(msg.sender, _plotId), "EBG: Caller is not owner or approved");
        plots[_plotId].name = _name;
        emit PlotNameChanged(_plotId, _name);
    }

    /// @notice Gets the details of a specific plot.
    /// @param _plotId The ID of the plot.
    /// @return Plot struct containing plot data.
    function getPlotDetails(uint256 _plotId) public view plotExists(_plotId) returns (Plot memory) {
        return plots[_plotId];
    }

    /// @notice Gets the list of plots owned by a specific user.
    /// @param _user The address of the user.
    /// @return An array of plot token IDs owned by the user.
    // Note: Efficiently getting *all* plot IDs for a user when plots can be transferred
    // is tricky with simple mappings. A common pattern is to track this in a separate
    // array per user or rely on subgraph indexing. For this example, we'll simulate
    // by returning a placeholder or requiring external indexing. A simple mapping
    // doesn't allow iteration.
    // A better on-chain approach uses a list of plot IDs per user, updated on transfer.
    // Let's add that for the demo, although it adds gas cost to transfers.

    mapping(address => uint256[]) private _userPlotList; // user => list of plot tokenIds

    function _addPlotToUserList(address user, uint256 tokenId) internal {
        _userPlotList[user].push(tokenId);
    }

    function _removePlotFromUserList(address user, uint256 tokenId) internal {
        uint256[] storage userPlots = _userPlotList[user];
        for (uint i = 0; i < userPlots.length; i++) {
            if (userPlots[i] == tokenId) {
                userPlots[i] = userPlots[userPlots.length - 1]; // Swap with last element
                userPlots.pop(); // Remove last element
                return;
            }
        }
    }

    // Override transfer/safeTransferFrom to update the user plot list
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        _removePlotFromUserList(from, tokenId);
        _addPlotToUserList(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        super.safeTransferFrom(from, to, tokenId);
        _removePlotFromUserList(from, tokenId);
        _addPlotToUserList(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        super.safeTransferFrom(from, to, tokenId, data);
        _removePlotFromUserList(from, tokenId);
        _addPlotToUserList(to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        _addPlotToUserList(to, tokenId);
    }

     function _burn(uint256 tokenId) internal override {
        address owner = ownerOf(tokenId);
        super._burn(tokenId);
        _removePlotFromUserList(owner, tokenId);
        // _update logic handles plot/bloom deletion
    }

    function getUserGardens(address _user) public view returns (uint256[] memory) {
        return _userPlotList[_user];
    }


    /// @notice Gets the list of bloom IDs currently on a specific plot.
    /// @param _plotId The ID of the plot.
    /// @return An array of bloom IDs.
    function getBloomsOnPlot(uint256 _plotId) public view plotExists(_plotId) returns (uint256[] memory) {
        return plots[_plotId].bloomIds;
    }


    // --- Bloom Management & Interaction ---

    /// @notice Plants a new bloom on a plot owned by the caller.
    /// @param _plotId The ID of the plot to plant on.
    /// @param _bloomTypeId The type of bloom to plant.
    function plantBloom(uint256 _plotId, uint8 _bloomTypeId) public plotExists(_plotId) hasGardenerEnergy(COST_PLANT_BLOOM) {
        require(ownerOf(_plotId) == msg.sender, "EBG: Caller does not own this plot");
        require(bloomTypes[_bloomTypeId].name != "", "EBG: Invalid bloom type"); // Check if bloom type exists

        _spendGardenerEnergy(msg.sender, COST_PLANT_BLOOM);

        _bloomIds.increment();
        uint256 newBloomId = _bloomIds.current();

        blooms[newBloomId] = Bloom({
            bloomId: newBloomId,
            plotId: _plotId,
            bloomTypeId: _bloomTypeId,
            growthStage: 0, // Starts as seedling
            resilience: bloomTypes[_bloomTypeId].baseResilience,
            etherAffinity: bloomTypes[_bloomTypeId].baseEtherAffinity,
            lastInteractionBlock: uint48(block.number),
            plantedBlock: uint48(block.number),
            owner: msg.sender, // Snapshot of planter
            exists: true
        });

        plots[_plotId].bloomIds.push(newBloomId); // Add bloom ID to plot's list

        emit BloomPlanted(_plotId, newBloomId, _bloomTypeId);
    }

    /// @notice Nurtures a bloom to encourage growth and improve resilience.
    /// @param _bloomId The ID of the bloom to nurture.
    function nurtureBloom(uint256 _bloomId) public bloomExists(_bloomId) hasGardenerEnergy(COST_NURTURE_BLOOM) {
        require(ownerOf(blooms[_bloomId].plotId) == msg.sender, "EBG: Caller does not own the plot of this bloom");

        _spendGardenerEnergy(msg.sender, COST_NURTURE_BLOOM);

        Bloom storage bloom = blooms[_bloomId];
        _updateBloomState(_bloomId); // Update state based on time passed

        // Apply nurture effects AFTER natural growth/decay
        bloom.growthStage = Math.min(MAX_GROWTH_STAGE, bloom.growthStage + 10); // Direct growth boost
        bloom.resilience = Math.min(MAX_RESILIENCE, bloom.resilience + 5); // Resilience boost
        bloom.lastInteractionBlock = uint48(block.number); // Reset interaction timer

        emit BloomNurtured(_bloomId, msg.sender, bloom.growthStage);
    }

    /// @notice Attempts to cross-pollinate two blooms on plots owned by the caller.
    /// @param _bloomId1 The ID of the first parent bloom.
    /// @param _bloomId2 The ID of the second parent bloom.
    // Note: Cross-pollination logic can be very complex. This is a simplified example.
    function crossPollinate(uint256 _bloomId1, uint256 _bloomId2) public bloomExists(_bloomId1) bloomExists(_bloomId2) hasGardenerEnergy(COST_CROSS_POLLINATE) {
        Bloom storage bloom1 = blooms[_bloomId1];
        Bloom storage bloom2 = blooms[_bloomId2];

        require(ownerOf(bloom1.plotId) == msg.sender && ownerOf(bloom2.plotId) == msg.sender, "EBG: Caller must own plots of both parent blooms");
        require(bloom1.bloomId != bloom2.bloomId, "EBG: Cannot cross-pollinate a bloom with itself");
        require(bloomTypes[bloom1.bloomTypeId].canCrossPollinate && bloomTypes[bloom2.bloomTypeId].canCrossPollinate, "EBG: One or both bloom types cannot be cross-pollinated");
        require(bloom1.growthStage > MAX_GROWTH_STAGE / 2 && bloom2.growthStage > MAX_GROWTH_STAGE / 2, "EBG: Blooms must be mature enough to cross-pollinate");

        _spendGardenerEnergy(msg.sender, COST_CROSS_POLLINATE);

        // --- Simplified Cross-Pollination Logic ---
        // This is a placeholder. Real logic could involve:
        // - Averaging traits (resilience, affinity)
        // - Introducing randomness based on traits or external factors
        // - Probability of creating a specific new bloom type based on parent types
        // - Chance of failure
        // - Consuming Bloom 'seed' state or reducing growth stage

        uint8 newBloomTypeId = bloom1.bloomTypeId; // Simple default
        uint8 newResilience = uint8((bloom1.resilience + bloom2.resilience) / 2);
        uint8 newEtherAffinity = uint8((bloom1.etherAffinity + bloom2.etherAffinity) / 2);

        // Add some basic randomness based on block hash (not truly random, but simple)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.number, _bloomId1, _bloomId2, msg.sender)));
        if (seed % 10 < 2) { // 20% chance of slight trait variation
             newResilience = uint8(Math.min(MAX_RESILIENCE, newResilience + seed % 10));
             newEtherAffinity = uint8(Math.min(MAX_ETHER_AFFINITY, newEtherAffinity + seed % 10));
        }

        // Example: Simple chance to produce a different type (requires type 3 to exist)
        if (seed % 100 < 5 && bloomTypes[3].name != "") { // 5% chance for type 3 offspring
             newBloomTypeId = 3;
             newResilience = bloomTypes[3].baseResilience; // Override with new type's base stats
             newEtherAffinity = bloomTypes[3].baseEtherAffinity;
        }


        // --- Create the new Bloom ---
        _bloomIds.increment();
        uint256 newBloomId = _bloomIds.current();
        uint256 targetPlotId = bloom1.plotId; // New bloom appears on parent1's plot

         blooms[newBloomId] = Bloom({
            bloomId: newBloomId,
            plotId: targetPlotId,
            bloomTypeId: newBloomTypeId,
            growthStage: 0, // Starts as seedling
            resilience: newResilience,
            etherAffinity: newEtherAffinity,
            lastInteractionBlock: uint48(block.number),
            plantedBlock: uint48(block.number),
            owner: msg.sender, // The one who performed the pollination
            exists: true
        });

        plots[targetPlotId].bloomIds.push(newBloomId); // Add new bloom to plot

        // Optionally affect parents (reduce growth, consume 'seed' state)
        _updateBloomState(_bloomId1); // Update state based on time
        _updateBloomState(_bloomId2); // Update state based on time
        bloom1.growthStage = Math.max(0, bloom1.growthStage / 2); // Halve parent growth stages
        bloom2.growthStage = Math.max(0, bloom2.growthStage / 2);
        bloom1.lastInteractionBlock = uint48(block.number); // Reset timers
        bloom2.lastInteractionBlock = uint48(block.number);


        emit BloomsCrossPollinated(_bloomId1, _bloomId2, newBloomId);
    }


    /// @notice Harvests a mature bloom, removing it but potentially yielding points or seeds.
    /// @param _bloomId The ID of the bloom to harvest.
    function harvestBloom(uint256 _bloomId) public bloomExists(_bloomId) hasGardenerEnergy(COST_HARVEST_BLOOM) {
        require(ownerOf(blooms[_bloomId].plotId) == msg.sender, "EBG: Caller does not own the plot of this bloom");
        _updateBloomState(_bloomId); // Ensure state is up-to-date
        require(blooms[_bloomId].growthStage >= 80, "EBG: Bloom is not mature enough to harvest"); // Example maturity threshold

        _spendGardenerEnergy(msg.sender, COST_HARVEST_BLOOM); // Cost to harvest

        // --- Harvest Yield Logic ---
        // This is simplified. Could yield:
        // - Gardener Energy
        // - A new BloomType seed ID
        // - A share of the Nutrient Pool (complex)
        // - Reputation points

        // For this demo: Yields some Gardener Energy based on original Ether Affinity
        uint256 energyYield = blooms[_bloomId].etherAffinity * 3; // Example yield calculation
        _userGardenerEnergy[msg.sender] = Math.min(MAX_GARDENER_ENERGY, _userGardenerEnergy[msg.sender] + energyYield);
        // Note: This doesn't use the _replenish logic's max cap, but explicitly caps at MAX_GARDENER_ENERGY.

        _pruneBloomInternal(_bloomId); // Remove the bloom

        emit BloomHarvested(_bloomId, msg.sender);
        emit GardenerEnergySpent(msg.sender, COST_HARVEST_BLOOM, _userGardenerEnergy[msg.sender]); // Also emit spend for cost
        emit GardenerEnergySpent(msg.sender, (0 - energyYield), _userGardenerEnergy[msg.sender]); // Emit gain (using negative for simple logging distinction)

    }

     /// @notice Removes a bloom from a plot without a yield (e.g., dead bloom, unwanted).
     /// @param _bloomId The ID of the bloom to prune.
    function pruneBloom(uint256 _bloomId) public bloomExists(_bloomId) hasGardenerEnergy(COST_PRUNE_BLOOM) {
        require(ownerOf(blooms[_bloomId].plotId) == msg.sender, "EBG: Caller does not own the plot of this bloom");
         // No maturity check - can prune at any stage

        _spendGardenerEnergy(msg.sender, COST_PRUNE_BLOOM);

        _pruneBloomInternal(_bloomId); // Internal prune logic

        emit BloomPruned(_bloomId, msg.sender);
    }

    /// @dev Internal function to handle bloom removal logic (used by harvest and prune).
    function _pruneBloomInternal(uint256 _bloomId) internal {
        Bloom storage bloom = blooms[_bloomId];
        require(bloom.exists, "EBG: Bloom not found for pruning"); // Double check exists

        bloom.exists = false; // Mark as non-existent

        // Remove bloom ID from the plot's bloomIds array
        Plot storage plot = plots[bloom.plotId];
        uint256 bloomCount = plot.bloomIds.length;
        for (uint i = 0; i < bloomCount; i++) {
            if (plot.bloomIds[i] == _bloomId) {
                // Swap with the last element and pop
                plot.bloomIds[i] = plot.bloomIds[bloomCount - 1];
                plot.bloomIds.pop();
                break; // Found and removed
            }
        }

        // Optional: Clean up bloom data completely (more gas) or leave marked as exists=false
        // For efficiency, leaving marked is common unless state variables need explicit zeroing.
        // If struct contains dynamic arrays or strings, need to clean them. Our struct is fixed size.
    }


    /// @notice Gets the details of a specific bloom.
    /// @param _bloomId The ID of the bloom.
    /// @return Bloom struct containing bloom data.
    function getBloomDetails(uint256 _bloomId) public view bloomExists(_bloomId) returns (Bloom memory) {
        // Note: This returns the *current* state. Callers interested in time-sensitive
        // state like growthStage should understand this is a snapshot.
        return blooms[_bloomId];
    }

    // --- Simulation & State ---

    /// @dev Internal function to update a bloom's state based on time and environmental factors.
    /// Called automatically by interaction functions that target a bloom.
    /// @param _bloomId The ID of the bloom to update.
    function _updateBloomState(uint256 _bloomId) internal {
        Bloom storage bloom = blooms[_bloomId];
        require(bloom.exists, "EBG: Bloom does not exist for update");

        uint256 blocksPassed = block.number - bloom.lastInteractionBlock;
        if (blocksPassed == 0) {
            return; // No time has passed since last update/interaction
        }

        // --- Growth/Decay Logic ---
        // Factors:
        // - Time passed (blocksPassed)
        // - BloomType growth/decay rate
        // - Resilience (resists decay)
        // - Environmental Parameters

        BloomType memory bloomType = bloomTypes[bloom.bloomTypeId];
        require(bloomType.name != "", "EBG: Invalid bloom type during update"); // Should not happen if planted correctly

        int256 growthChange = 0;

        // Base growth based on type and time
        growthChange += int256(blocksPassed * bloomType.growthRate);

        // Base decay based on type and time
        growthChange -= int256(blocksPassed * bloomType.decayRate);

        // Resilience resists decay (higher resilience = less negative growth)
        // Simplified: Resilience reduces the *magnitude* of decay factor
        uint256 decayResistanceFactor = MAX_RESILIENCE - bloom.resilience; // 0 (high res) to 100 (low res)
        growthChange += int256(blocksPassed * bloomType.decayRate * decayResistanceFactor / MAX_RESILIENCE); // Add back some decay based on resilience

        // Environment Effects (Simplified interaction)
        int256 sunshineEffect = int256(environmentalParameters[uint8(EnvironmentParameter.SunshineIntensity)] - 50); // + for high, - for low
        int256 rainfallEffect = int256(environmentalParameters[uint8(EnvironmentParameter.RainfallAmount)] - 50); // + for high, - for low
        int256 etherEffect = int256(environmentalParameters[uint8(EnvironmentParameter.EtherDensity)] - 50); // + for high, - for low

        // Combine effects - example: Sunshine & Rainfall generally positive, Ether Affinity interacts with EtherDensity
        growthChange += (sunshineEffect + rainfallEffect) / 10; // Simple environmental modifier

        // Ether Affinity interaction: blooms with high affinity grow better in high ether density
        growthChange += (etherEffect * int252(bloom.etherAffinity)) / (MAX_ETHER_AFFINITY * 10);


        // Apply the calculated growth change
        int256 currentGrowth = int256(bloom.growthStage);
        int256 newGrowth = currentGrowth + growthChange;

        // Clamp growth stage between 0 and MAX_GROWTH_STAGE
        if (newGrowth < 0) {
            bloom.growthStage = 0;
        } else if (newGrowth > int256(MAX_GROWTH_STAGE)) {
            bloom.growthStage = uint8(MAX_GROWTH_STAGE);
        } else {
            bloom.growthStage = uint8(newGrowth);
        }

        // Update last interaction block - this is crucial!
        bloom.lastInteractionBlock = uint48(block.number);

        // Optional: Event for significant state change? Or too noisy? Let's skip for gas.

        // Optional: Auto-prune if growth hits 0 and is neglected?
        // If bloom.growthStage is 0 and blocksPassed is very high, auto-prune.
        // Let's skip auto-prune for this demo to keep it simpler. Decay to 0 is sufficient.
    }


    /// @notice Gets the total number of blooms that have ever existed (including harvested/pruned).
    /// @return The total bloom count.
    function getBloomCount() public view returns (uint256) {
        return _bloomIds.current();
    }

    /// @notice Gets the total number of plots that have ever existed (including burned).
    /// @return The total plot count.
    function getPlotCount() public view returns (uint256) {
        return _plotTokenIds.current();
    }


    // --- Gardener Energy System ---

    /// @dev Internal helper to replenish user's gardener energy based on blocks passed.
    /// Called by any function that checks or spends energy.
    /// @param _user The address of the user.
    function _replenishGardenerEnergy(address _user) internal {
        uint48 lastBlock = _lastEnergyReplenishBlock[_user];
        uint256 blocksPassed = block.number - lastBlock;

        if (blocksPassed > 0) {
            uint256 replenished = blocksPassed * ENERGY_REPLENISH_PER_BLOCK;
            _userGardenerEnergy[_user] = Math.min(MAX_GARDENER_ENERGY, _userGardenerEnergy[_user] + replenished);
            _lastEnergyReplenishBlock[_user] = uint48(block.number);
        }
    }

    /// @dev Internal helper to spend user's gardener energy. Assumes _replenishGardenerEnergy
    /// has just been called by the calling public/external function.
    /// @param _user The address of the user.
    /// @param _amount The amount of energy to spend.
    function _spendGardenerEnergy(address _user, uint256 _amount) internal {
        // require(_userGardenerEnergy[_user] >= _amount, "EBG: Insufficient Gardener Energy"); // Checked by hasGardenerEnergy modifier
        _userGardenerEnergy[_user] -= _amount;
        emit GardenerEnergySpent(_user, _amount, _userGardenerEnergy[_user]);
    }

    /// @notice Gets the current gardener energy of a user (after replenishment).
    /// @param _user The address of the user.
    /// @return The user's current gardener energy.
    function getUserGardenerEnergy(address _user) public view returns (uint256) {
        uint48 lastBlock = _lastEnergyReplenishBlock[_user];
        uint256 blocksPassed = block.number - lastBlock;
        uint256 replenished = blocksPassed * ENERGY_REPLENISH_PER_BLOCK;
        return Math.min(MAX_GARDENER_ENERGY, _userGardenerEnergy[_user] + replenished);
    }

    /// @notice Allows owner to set parameters for the Gardener Energy system.
    /// @param _maxEnergy The new maximum energy limit.
    /// @param _replenishRatePerBlock The new replenishment amount per block.
    function setGardenerEnergyParams(uint256 _maxEnergy, uint256 _replenishRatePerBlock) public onlyOwner {
        require(_maxEnergy > 0 && _replenishRatePerBlock > 0, "EBG: Parameters must be positive");
        // Note: Changing MAX_GARDENER_ENERGY could affect existing users above the new cap.
        // A more complex contract might handle this (e.g., grandfatheirng, gradual reduction).
        MAX_GARDENER_ENERGY = _maxEnergy;
        ENERGY_REPLENISH_PER_BLOCK = _replenishRatePerBlock;
    }

    /// @notice Gets the total theoretical maximum gardener energy across all users.
    /// (Useful for state tracking, not actual sum of current energy).
    /// @return The total gardener energy supply limit.
    function getTotalGardenerEnergySupply() public view returns (uint256) {
         // This doesn't track *actual* distributed energy, but the conceptual total limit per user.
         // Tracking actual total across all users would require iterating mappings or separate state.
         // Let's return the MAX_GARDENER_ENERGY as the "supply cap per user".
         // If we wanted total *potential* distributed, it would be MAX_GARDENER_ENERGY * total_users (hard to track efficiently).
         // So, let's clarify this returns the *per user* maximum.
         return MAX_GARDENER_ENERGY;
    }


    // --- Nutrient Pool ---

    /// @notice Allows anyone to deposit Ether into the Nutrient Pool.
    function depositIntoNutrientPool() public payable {
        require(msg.value > 0, "EBG: Deposit amount must be greater than zero");
        nutrientPoolBalance += msg.value; // Track balance conceptually, ETH is in contract balance
        emit NutrientPoolDeposited(msg.sender, msg.value);
    }

    /// @notice Allows the owner to withdraw Ether from the Nutrient Pool.
    /// @param _amount The amount of Ether to withdraw.
    /// @param _recipient The address to send the Ether to.
    function withdrawFromNutrientPool(uint256 _amount, address payable _recipient) public onlyOwner {
        require(_amount > 0, "EBG: Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "EBG: Insufficient contract balance");
        // Note: nutrientPoolBalance is conceptual. We withdraw from the contract's actual ETH balance.
        // A more robust system might tie withdrawals directly to the tracked balance.
        // For simplicity, we just ensure the contract *has* the ETH.
        // require(nutrientPoolBalance >= _amount, "EBG: Insufficient Nutrient Pool balance (conceptual)"); // Optional: enforce tracked balance
        // nutrientPoolBalance -= _amount; // Optional: deduct from tracked balance

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "EBG: ETH transfer failed");

        emit NutrientPoolWithdrawal(_recipient, _amount);
    }

    /// @notice Gets the current balance of the Nutrient Pool (contract ETH balance).
    function getNutrientPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Community & Reputation ---

    /// @notice Allows a user to observe a plot, potentially increasing their reputation.
    /// Can only observe a plot you don't own.
    /// @param _plotId The ID of the plot to observe.
    function observeGarden(uint256 _plotId) public plotExists(_plotId) {
        require(ownerOf(_plotId) != msg.sender, "EBG: Cannot observe your own garden");
        // Optional: Add a cooldown to prevent spamming observation
        // require(block.number > plots[_plotId].lastObservedBlock + 10, "EBG: Plot observed too recently"); // Example cooldown

        userReputation[msg.sender] += REP_OBSERVE_PLOT;
        plots[_plotId].lastObservedBlock = uint48(block.number); // Update observation time

        // Optional: Observing could give the *observed* garden a tiny boost or energy.
        // address plotOwner = ownerOf(_plotId);
        // _replenishGardenerEnergy(plotOwner); // Replenish owner energy
        // _userGardenerEnergy[plotOwner] = Math.min(MAX_GARDENER_ENERGY, _userGardenerEnergy[plotOwner] + REP_OBSERVE_PLOT); // Owner gets energy

        emit GardenObserved(_plotId, msg.sender, REP_OBSERVE_PLOT);
    }

    /// @notice Allows a user to endorse a plot they particularly like, significantly increasing their reputation.
    /// Can only endorse a plot you don't own.
    /// @param _plotId The ID of the plot to endorse.
    function endorseGarden(uint256 _plotId) public plotExists(_plotId) {
        require(ownerOf(_plotId) != msg.sender, "EBG: Cannot endorse your own garden");
        // Optional: Add cooldown or energy cost for endorsement
        // require(hasGardenerEnergy(COST_ENDORSE_GARDEN), "..."); // Define COST_ENDORSE_GARDEN
        // _spendGardenerEnergy(msg.sender, COST_ENDORSE_GARDEN);

        userReputation[msg.sender] += REP_ENDORSE_PLOT;
         // No need to update lastObservedBlock if only observation does that

        emit GardenEndorsed(_plotId, msg.sender, REP_ENDORSE_PLOT);
    }

    /// @notice Gets the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }


    // --- Environment Management ---

    /// @notice Allows the owner to set a global environmental parameter.
    /// Affects how blooms grow and decay.
    /// @param _paramType The type of environmental parameter (enum cast to uint8).
    /// @param _value The value for the parameter (0-100).
    function setEnvironmentalParameter(EnvironmentParameter _paramType, uint8 _value) public onlyOwner {
        // Basic validation on value range
        require(_value <= 100, "EBG: Parameter value must be between 0 and 100");
        environmentalParameters[uint8(_paramType)] = _value;
        emit EnvironmentParameterChanged(_paramType, _value);
    }

    /// @notice Gets the current values of all environmental parameters.
    /// @return An array of uint8 values corresponding to EnvironmentParameter enum order.
    function getEnvironmentalParameters() public view returns (uint8[] memory) {
        uint8[] memory params = new uint8[](3); // Hardcoded size based on enum
        params[uint8(EnvironmentParameter.SunshineIntensity)] = environmentalParameters[uint8(EnvironmentParameter.SunshineIntensity)];
        params[uint8(EnvironmentParameter.RainfallAmount)] = environmentalParameters[uint8(EnvironmentParameter.RainfallAmount)];
        params[uint8(EnvironmentParameter.EtherDensity)] = environmentalParameters[uint8(EnvironmentParameter.EtherDensity)];
        return params;
    }

     // --- Configuration ---

     /// @notice Allows the owner to define or update a type of bloom.
     /// @param _bloomTypeId The ID for this bloom type.
     /// @param _name The name of the bloom type.
     /// @param _baseResilience Base resilience for blooms of this type (0-100).
     /// @param _baseEtherAffinity Base ether affinity (0-100).
     /// @param _growthRate Growth rate per interaction/time factor (e.g., 1-10).
     /// @param _decayRate Decay rate per time factor (e.g., 1-10).
     /// @param _canCrossPollinate Whether blooms of this type can participate in cross-pollination.
    function setBloomTypeParameters(
        uint8 _bloomTypeId,
        string memory _name,
        uint8 _baseResilience,
        uint8 _baseEtherAffinity,
        uint8 _growthRate,
        uint8 _decayRate,
        bool _canCrossPollinate
    ) public onlyOwner {
        require(_name.length > 0, "EBG: Bloom type name cannot be empty");
        require(_baseResilience <= 100 && _baseEtherAffinity <= 100, "EBG: Base stats must be <= 100");
         require(_growthRate > 0 || _decayRate > 0, "EBG: Growth or decay rate must be non-zero");


        bloomTypes[_bloomTypeId] = BloomType({
            name: _name,
            baseResilience: _baseResilience,
            baseEtherAffinity: _baseEtherAffinity,
            growthRate: _growthRate,
            decayRate: _decayRate,
            canCrossPollinate: _canCrossPollinate
        });

        emit BloomTypeCreatedOrUpdated(_bloomTypeId, _name);
    }

    /// @notice Gets the parameters for a specific bloom type.
    /// @param _bloomTypeId The ID of the bloom type.
    /// @return BloomType struct containing type parameters.
    function getBloomTypeParameters(uint8 _bloomTypeId) public view returns (BloomType memory) {
        require(bloomTypes[_bloomTypeId].name != "", "EBG: Bloom type does not exist");
        return bloomTypes[_bloomTypeId];
    }


    // --- Utility/View ---

    /// @notice Gets a summary of key contract state variables.
    /// @return A tuple containing total plots, total blooms, nutrient pool balance, max energy, energy refill rate.
    function getContractStateSummary() public view returns (
        uint256 totalPlots,
        uint256 totalBlooms,
        uint256 nutrientPoolEthBalance,
        uint256 maxGardenerEnergy,
        uint256 energyRefillRatePerBlock
    ) {
        return (
            _plotTokenIds.current(),
            _bloomIds.current(),
            address(this).balance, // Actual ETH balance
            MAX_GARDENER_ENERGY,
            ENERGY_REPLENISH_PER_BLOCK
        );
    }

    // --- Fallback/Receive (for Nutrient Pool Deposits) ---
     receive() external payable {
        depositIntoNutrientPool();
    }
     fallback() external payable {
        depositIntoNutrientPool();
    }


}
```

---

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic On-Chain Entities (Blooms):** Blooms are not separate NFTs (though they *could* be). Instead, they are dynamic structs managed *within* the main contract, linked to a Plot NFT. Their state (`growthStage`, `resilience`, `etherAffinity`) changes over time and based on interactions. This is more complex than static NFT metadata.
2.  **On-Chain Simulation Mechanics:**
    *   **Time-Based Evolution:** Blooms evolve based on `block.number` differences (`_updateBloomState`), simulating growth and decay.
    *   **Parameter-Based Effects:** Bloom evolution is influenced by their inherent `BloomType` parameters (`growthRate`, `decayRate`) and global `environmentalParameters`.
    *   **Interaction-Triggered Updates:** The `_updateBloomState` function is called *by* interaction functions (`nurture`, `pollinate`, `harvest`, `prune`), processing accrued time effects when a user acts.
3.  **Resource Management (Gardener Energy):** Implements a per-user "energy" system (`_userGardenerEnergy`) that depletes on actions and replenishes based on block time. This gates user activity without requiring staking or external tokens for *every* minor action.
4.  **Complex Interaction (Cross-Pollination):** The `crossPollinate` function simulates breeding/combining traits. While the provided logic is a simplified placeholder, it demonstrates the capability for complex on-chain mechanics involving multiple state variables and potential randomness (using `keccak256` with block data - note this is not truly random but sufficient for simple in-game variation).
5.  **Shared Resource Pool (Nutrient Pool):** A mechanism for users to contribute ETH to a shared pool, which could conceptually fuel the ecosystem or be managed by the community/DAO (via the `withdrawFromNutrientPool` owner function, potentially upgradeable to a DAO).
6.  **Community Interaction & Reputation:** Includes `observeGarden` and `endorseGarden` functions that allow users to interact with *other* people's gardens, building their personal `userReputation`.
7.  **Decentralized Garden State:** The state of each plot and bloom is stored directly on the blockchain, owned and managed by the users, rather than relying on a centralized server.
8.  **Non-Standard NFT Use:** The ERC721 token represents the *Plot*, which acts as a container for the dynamic `Bloom` structs, rather than the Bloom itself being a separate NFT in this design. This allows for managing collections of dynamic entities within a single token.

This contract provides a framework for a rich, interactive on-chain simulation with dynamic elements and multiple intertwined systems, going beyond basic token or static NFT contracts.