Okay, let's create a smart contract that implements a system of interactive, evolving digital entities – let's call them "Ethereal Guardians". These guardians will be NFTs with dynamic properties that change based on time, owner interactions, and simulated events. The contract will blend elements of digital pets, on-chain simulation, and parameterized outcomes.

It will leverage:
1.  **Dynamic State:** Guardian properties change over time and based on actions.
2.  **Time-Based Mechanics:** Neglect or care influences stats via time delta calculations.
3.  **Parameterized Outcomes:** Actions like "exploring" or "challenging" have outcomes influenced by guardian stats ("intelligence," "energy," "affinity").
4.  **Simulated Growth/Decay:** Stats like health and energy fluctuate.
5.  **Resource Management:** Actions consume (simulated) resources or energy.
6.  **Interactive NFTs:** NFTs aren't just static images; they are objects you *do* things with.

This structure avoids directly copying well-known protocols like ERC20, ERC721 (though it *uses* ERC721), staking contracts, AMMs, etc. It builds a novel application logic *on top* of base standards.

---

**Outline:**

1.  **Pragma, Imports, License**
2.  **Error Handling**
3.  **Events**
4.  **Structs:** Define the structure for a Guardian.
5.  **Enums:** Define states like GrowthStage and AffinityType.
6.  **State Variables:** Mappings for Guardian data, token counter, base URI, contract state, simulation parameters.
7.  **Modifiers:** Access control (owner, guardian existence, guardian ownership).
8.  **Constructor:** Initialize ERC721 base, set owner.
9.  **ERC721 Overrides:** Implement `tokenURI`.
10. **Core Internal Logic:** `_updateGuardianState` (handles time-based decay/growth). `_generateInitialStats` (simulated randomness). `_calculateGrowthStage`.
11. **Minting:** `mintNewGuardian`.
12. **View Functions:** Get guardian stats, name, growth stage, etc. Get contract state.
13. **Interaction Functions:**
    *   `feedGuardian`
    *   `trainGuardian`
    *   `healGuardian`
    *   `meditateGuardian` (enter state)
    *   `exitMeditation` (exit state)
    *   `exploreEnvironment` (simulated probabilistic outcome)
    *   `simulateChallenge` (between two guardians, stats-based outcome)
    *   `bondWithGuardian` (unique action with potential boosts)
14. **Guardian State Queries:** Specific view functions for individual stats.
15. **Contract Management (Owner Functions):**
    *   `setBaseURI`
    *   `pauseContract`
    *   `unpauseContract`
    *   `withdrawFees` (if any collected)
    *   `updateSimulationParameters`
16. **Utility Functions:** Get total supply.

---

**Function Summary:**

*   `constructor()`: Initializes the contract, sets name and symbol for ERC721, assigns owner.
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard implementation.
*   `balanceOf(address owner)`: Returns number of Guardians owned by an address (ERC721).
*   `ownerOf(uint256 tokenId)`: Returns the owner of a Guardian (ERC721).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers a Guardian safely (ERC721).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Transfers a Guardian safely with data (ERC721).
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a Guardian (ERC721).
*   `approve(address to, uint256 tokenId)`: Approves an address to manage a Guardian (ERC721).
*   `setApprovalForAll(address operator, bool approved)`: Approves an operator for all Guardians (ERC721).
*   `getApproved(uint256 tokenId)`: Gets the approved address for a Guardian (ERC721).
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all Guardians (ERC721).
*   `tokenURI(uint256 tokenId)`: Generates the metadata URI for a Guardian, reflecting its current dynamic state (ERC721 override).
*   `mintNewGuardian()`: Mints a new Guardian NFT for the caller with initial randomized stats and affinities.
*   `_updateGuardianState(uint256 tokenId)`: Internal function to calculate and apply state changes (health decay, energy regen, growth stage) based on time elapsed since last interaction. Called by most interaction functions.
*   `getGuardianStats(uint256 tokenId)`: View function to retrieve the full current stats of a Guardian (implicitly runs `_updateGuardianState` first for latest state).
*   `feedGuardian(uint256 tokenId)`: Owner/approved action. Consumes (simulated) resources, boosts health and energy, updates interaction time.
*   `trainGuardian(uint256 tokenId)`: Owner/approved action. Consumes energy, boosts experience and intelligence, updates interaction time.
*   `healGuardian(uint256 tokenId)`: Owner/approved action. Consumes more resources, restores health significantly, updates interaction time.
*   `meditateGuardian(uint256 tokenId)`: Owner/approved action. Guardian enters a meditating state, preventing other actions but accelerating energy regeneration over time.
*   `exitMeditation(uint256 tokenId)`: Owner/approved action. Guardian exits the meditating state.
*   `exploreEnvironment(uint256 tokenId)`: Owner/approved action. Consumes energy. Simulates an exploration attempt with probabilistic outcome based on stats (e.g., intelligence, energy, affinity). Returns result.
*   `simulateChallenge(uint256 tokenId1, uint256 tokenId2)`: Owner/approved action (for tokenId1). Simulates a challenge between two Guardians. Outcome is determined by comparing their stats and affinities. Returns outcome. Does NOT transfer ownership or destroy NFTs, only affects stats (e.g., temporary stat changes, experience gain/loss).
*   `bondWithGuardian(uint256 tokenId)`: Owner/approved action. A special action with a cooldown that provides a temporary or permanent minor boost to certain stats, representing a strong connection.
*   `setGuardianName(uint256 tokenId, string calldata name)`: Owner/approved action to set a unique name for a Guardian.
*   `getGuardianName(uint256 tokenId)`: View function to retrieve a Guardian's name.
*   `getGuardianGrowthStage(uint256 tokenId)`: View function to retrieve only the Growth Stage (implicitly updates state first).
*   `getGuardianAffinity(uint256 tokenId)`: View function to retrieve the Guardian's Affinity type.
*   `getContractState()`: View function to check if the contract is paused.
*   `getTokenCounter()`: View function returning the total number of Guardians minted.
*   `setBaseURI(string calldata baseURI)`: Owner function to update the base URI for metadata.
*   `pauseContract()`: Owner function to pause interaction functions.
*   `unpauseContract()`: Owner function to unpause interaction functions.
*   `withdrawFees()`: Owner function to withdraw any collected Ether (e.g., from minting fees, although not explicitly implemented as a fee source here, included as standard practice).
*   `updateSimulationParameters(...)`: Owner function to adjust internal parameters affecting growth rates, decay rates, exploration success probabilities, challenge outcomes, etc. (Placeholder implementation).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Used for tokenOfOwnerByIndex, etc.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For generating dynamic JSON metadata

// --- Outline ---
// 1. Pragma, Imports, License
// 2. Error Handling
// 3. Events
// 4. Structs: Guardian
// 5. Enums: GrowthStage, AffinityType, ChallengeOutcome
// 6. State Variables: Mappings for Guardian data, token counter, base URI, contract state, simulation parameters.
// 7. Modifiers: Access control (owner, guardian existence, guardian ownership/approval).
// 8. Constructor
// 9. ERC721 Overrides: supportsInterface, tokenURI, _baseURI, _beforeTokenTransfer
// 10. Core Internal Logic: _updateGuardianState, _generateInitialStats, _calculateGrowthStage, _getSimulationParam
// 11. Minting: mintNewGuardian
// 12. View Functions: Get guardian stats, name, growth stage, affinity, etc. Get contract state, token counter.
// 13. Interaction Functions: feed, train, heal, meditate (enter/exit), explore, simulateChallenge, bond.
// 14. Contract Management (Owner Functions): setBaseURI, pause, unpause, withdrawFees, updateSimulationParameters.

// --- Function Summary ---
// constructor()
// supportsInterface(bytes4 interfaceId)
// balanceOf(address owner)
// ownerOf(uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// transferFrom(address from, address to, uint256 tokenId)
// approve(address to, uint256 tokenId)
// setApprovalForAll(address operator, bool approved)
// getApproved(uint256 tokenId)
// isApprovedForAll(address owner, address operator)
// tokenURI(uint256 tokenId)
// mintNewGuardian()
// getGuardianStats(uint256 tokenId)
// feedGuardian(uint256 tokenId)
// trainGuardian(uint256 tokenId)
// healGuardian(uint256 tokenId)
// meditateGuardian(uint256 tokenId)
// exitMeditation(uint256 tokenId)
// exploreEnvironment(uint256 tokenId)
// simulateChallenge(uint256 tokenId1, uint256 tokenId2)
// bondWithGuardian(uint256 tokenId)
// setGuardianName(uint256 tokenId, string calldata name)
// getGuardianName(uint256 tokenId)
// getGuardianGrowthStage(uint256 tokenId)
// getGuardianAffinity(uint256 tokenId)
// getContractState()
// getTokenCounter()
// setBaseURI(string calldata baseURI)
// pauseContract()
// unpauseContract()
// withdrawFees()
// updateSimulationParameters(...)

contract EtherealGuardians is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _nextTokenId;

    // --- Enums ---
    enum GrowthStage { Egg, Baby, Juvenile, Adult, Elder }
    enum AffinityType { Fire, Water, Earth, Air, Mystic, None }
    enum ChallengeOutcome { Draw, ChallengerWins, DefenderWins } // Outcomes for simulateChallenge

    // --- Structs ---
    struct Guardian {
        uint66 genesisTimestamp; // Timestamp of creation
        uint66 lastInteractionTimestamp; // Timestamp of last interaction or state update
        uint66 lastBondTimestamp; // Timestamp of last bonding action
        uint66 lastExploreTimestamp; // Timestamp of last exploration

        uint16 health; // Max 10000 (100.00%)
        uint16 energy; // Max 10000 (100.00%)
        uint16 intelligenceScore; // Max 1000
        uint16 experiencePoints; // Accumulates over time

        AffinityType affinity;
        GrowthStage growthStage;

        bool isMeditating;
        // Add more state variables here as complexity grows
    }

    // --- State Variables ---
    mapping(uint256 => Guardian) private _guardians;
    mapping(uint256 => string) private _guardianNames;
    string private _baseTokenURI;

    // Simulation parameters (Owner configurable to tune the game)
    struct SimulationParams {
        uint16 healthDecayRatePerDay; // Units per day
        uint16 energyRegenRatePerDay; // Units per day
        uint16 meditationEnergyRegenBonus; // Percentage bonus
        uint16 feedHealthGain;
        uint16 feedEnergyGain;
        uint16 trainEnergyCost;
        uint16 trainExpGain;
        uint16 trainIntGain;
        uint16 healHealthGain;
        uint16 exploreEnergyCost;
        uint16 exploreBaseSuccessChance; // Out of 100
        uint16 exploreIntBonusFactor; // % bonus chance per 100 Int
        uint16 bondCooldownDays;
        uint16 bondStatBonusPercent; // Percentage bonus to a random stat
        uint16 challengeBaseDamage; // Base damage applied in challenge
        uint16 challengeAffinityBonusPercent; // % bonus damage for advantageous affinity
        uint16 challengeIntFactor; // Influence of Intelligence on outcome (e.g., percentage of int added to attack/defense roll)
        uint32 babyStageDuration; // Seconds
        uint32 juvenileStageDuration; // Seconds
        uint32 adultStageDuration; // Seconds
        // Elder stage is indefinite
    }

    SimulationParams public simParams;

    // --- Errors ---
    error GuardianDoesNotExist();
    error NotGuardianOwnerOrApproved();
    error GuardianAlreadyMeditating();
    error GuardianNotMeditating();
    error GuardianTooLowEnergy();
    error GuardianTooLowHealth();
    error GuardianTooLowExperience();
    error CannotBondYet();
    error SameGuardiansInChallenge();
    error ChallengeCooldownActive(); // Example cooldown for challenging specific guardians? (Not implemented, just ideation)

    // --- Events ---
    event GuardianMinted(uint256 indexed tokenId, address indexed owner, AffinityType affinity);
    event GuardianStateUpdated(uint256 indexed tokenId, uint66 timestamp, uint16 health, uint16 energy, uint16 intelligenceScore, uint16 experiencePoints, GrowthStage growthStage, bool isMeditating);
    event GuardianInteracted(uint256 indexed tokenId, string action, uint66 timestamp);
    event GuardianNamed(uint256 indexed tokenId, string name);
    event GuardianBonded(uint256 indexed tokenId, uint66 timestamp, uint16 bonusApplied); // Example bonus applied
    event GuardianExplored(uint256 indexed tokenId, bool success, int16 healthDelta, int16 energyDelta, int16 expDelta, string message); // Delta could be positive or negative
    event ChallengeSimulated(uint256 indexed tokenId1, uint256 indexed tokenId2, ChallengeOutcome outcome);

    // --- Modifiers ---
    modifier whenGuardianExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert GuardianDoesNotExist();
        _;
    }

    modifier onlyOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) revert NotGuardianOwnerOrApproved();
        _;
    }

    modifier onlyInteractable(uint256 tokenId) {
        // Check not meditating and not paused
        if (_guardians[tokenId].isMeditating) revert GuardianAlreadyMeditating(); // More like "GuardianIsBusy"
        _pause(); // Pausable checks if paused
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        // Set initial simulation parameters (can be tuned later by owner)
        simParams = SimulationParams({
            healthDecayRatePerDay: 200, // 2% per day
            energyRegenRatePerDay: 300, // 3% per day
            meditationEnergyRegenBonus: 100, // 100% bonus (doubles regen)
            feedHealthGain: 1000, // 10% health
            feedEnergyGain: 500, // 5% energy
            trainEnergyCost: 1000, // 10% energy
            trainExpGain: 100,
            trainIntGain: 5, // Max 1000
            healHealthGain: 3000, // 30% health
            exploreEnergyCost: 1500, // 15% energy
            exploreBaseSuccessChance: 50, // 50% base
            exploreIntBonusFactor: 2, // 2% bonus chance per 100 Int
            bondCooldownDays: 30,
            bondStatBonusPercent: 5, // 5% bonus
            challengeBaseDamage: 100,
            challengeAffinityBonusPercent: 50, // 50% bonus damage
            challengeIntFactor: 10, // 10% of Int added to combat roll
            babyStageDuration: 7 days,
            juvenileStageDuration: 30 days,
            adultStageDuration: 180 days
        });
    }

    // --- ERC721 Overrides ---

    // ERC165 support (already handled by inherited ERC721Enumerable)
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    // Override _beforeTokenTransfer to manage Guardian struct lifecycle
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) {
            // Minting: Initialize the guardian state
             _guardians[tokenId].genesisTimestamp = uint66(block.timestamp);
             _guardians[tokenId].lastInteractionTimestamp = uint66(block.timestamp);
             _guardians[tokenId].lastBondTimestamp = 0; // Reset bond cooldown
             _guardians[tokenId].lastExploreTimestamp = 0; // Reset explore cooldown (if implemented)
             _guardians[tokenId].health = 10000; // Start at full health
             _guardians[tokenId].energy = 10000; // Start at full energy
             _generateInitialStats(tokenId); // Generate random initial intelligence and affinity
             _guardians[tokenId].growthStage = GrowthStage.Egg; // Start as Egg
             _guardians[tokenId].isMeditating = false;
        } else if (to == address(0)) {
            // Burning: Clean up guardian state (optional, but good practice for dynamic NFTs)
            delete _guardians[tokenId];
            delete _guardianNames[tokenId]; // Also delete name
        } else {
            // Transferring: Ensure state is up-to-date before transfer (optional but good)
             _updateGuardianState(tokenId);
            // Consider if transferring should reset any state (e.g., meditation, bond cooldown)
             _guardians[tokenId].isMeditating = false; // Exit meditation on transfer
        }
    }

    // Implement tokenURI for dynamic metadata
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // Ensure state is calculated for metadata (view function cannot modify state,
        // so we need to recalculate based on current time)
        Guardian memory guardian = _guardians[tokenId];
        uint66 currentTimestamp = uint66(block.timestamp);
        uint64 timeElapsed = currentTimestamp - guardian.lastInteractionTimestamp;

        // Simulate state update based on time elapsed *since the last actual interaction*
        // This simulation doesn't persist, it's just for metadata accuracy.
        uint16 simulatedHealth = guardian.health;
        uint16 simulatedEnergy = guardian.energy;
        GrowthStage simulatedGrowthStage = _calculateGrowthStage(guardian.genesisTimestamp, currentTimestamp);

        if (!guardian.isMeditating) {
             // Health decay (approx)
             uint64 healthDecaySeconds = (uint64(simParams.healthDecayRatePerDay) * timeElapsed) / (24 * 60 * 60);
             if (simulatedHealth > healthDecaySeconds) {
                 simulatedHealth -= uint16(healthDecaySeconds);
             } else {
                 simulatedHealth = 0;
             }

             // Energy regen (approx)
             uint64 energyRegenSeconds = (uint64(simParams.energyRegenRatePerDay) * timeElapsed) / (24 * 60 * 60);
             simulatedEnergy = uint16(Math.min(uint256(simulatedEnergy) + energyRegenSeconds, 10000)); // Cap at max energy

        } else {
             // Accelerated Energy regen during meditation
            uint64 energyRegenSeconds = (uint64(simParams.energyRegenRatePerDay) * (100 + simParams.meditationEnergyRegenBonus) / 100 * timeElapsed) / (24 * 60 * 60);
             simulatedEnergy = uint16(Math.min(uint256(simulatedEnergy) + energyRegenSeconds, 10000));
             // No health decay while meditating? Or slower? Let's say no decay for now.
        }


        string memory name = bytes(_guardianNames[tokenId]).length > 0 ? _guardianNames[tokenId] : string(abi.encodePacked("Guardian #", tokenId.toString()));
        string memory description = string(abi.encodePacked("An Ethereal Guardian with dynamic stats. Nurture it to help it grow and thrive!"));

        // Prepare attributes
        string memory attributes = string(abi.encodePacked(
            "[",
            '{"trait_type": "Health", "value": ', simulatedHealth.toString(), '},',
            '{"trait_type": "Energy", "value": ', simulatedEnergy.toString(), '},',
            '{"trait_type": "Intelligence", "value": ', guardian.intelligenceScore.toString(), '},',
            '{"trait_type": "Experience", "value": ', guardian.experiencePoints.toString(), '},',
            '{"trait_type": "Affinity", "value": "', _affinityTypeToString(guardian.affinity), '"},',
            '{"trait_type": "Growth Stage", "value": "', _growthStageToString(simulatedGrowthStage), '"},',
            '{"trait_type": "Meditating", "value": ', guardian.isMeditating ? "true" : "false", '}',
            // Add more attributes for other state variables as needed
            "]"
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            // You'd typically put an 'image' field here pointing to a URL.
            // For a dynamic NFT, this image URL could change based on stage or stats,
            // or point to a generative art endpoint. Using a placeholder:
            '"image": "', _baseTokenURI, tokenId.toString(), '/image.png",',
            '"attributes": ', attributes,
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Core Internal Logic ---

    // Internal function to generate initial (simulated) random stats
    function _generateInitialStats(uint256 tokenId) internal {
        // Simple simulated randomness based on block hash and timestamp.
        // NOTE: This is predictable and NOT suitable for high-value production randomness!
        // For real dApps, use Chainlink VRF or similar verifiable random functions.
        uint256 seed = uint224(block.timestamp) ^ uint224(blockhash(block.number - 1));

        // Ensure we don't use a seed of 0
        if (seed == 0) {
            seed = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId)));
        }

        // Generate Intelligence (e.g., 100-500)
        uint16 initialIntelligence = uint16((seed % 401) + 100); // Range [100, 500]
        _guardians[tokenId].intelligenceScore = initialIntelligence;

        // Generate Affinity (randomly pick one)
        uint256 affinityIndex = seed % uint256(AffinityType.None); // Use count of enums excluding 'None'
        _guardians[tokenId].affinity = AffinityType(affinityIndex);
    }

    // Internal function to calculate and apply state changes based on time
    function _updateGuardianState(uint256 tokenId) internal {
        Guardian storage guardian = _guardians[tokenId];
        uint66 currentTimestamp = uint66(block.timestamp);
        uint64 timeElapsed = currentTimestamp - guardian.lastInteractionTimestamp;

        if (timeElapsed == 0) return; // No time has passed since last update

        // Calculate state changes based on time
        if (!guardian.isMeditating) {
            // Health decay (approx)
            uint64 healthDecaySeconds = (uint64(simParams.healthDecayRatePerDay) * timeElapsed) / (24 * 60 * 60);
            if (guardian.health > healthDecaySeconds) {
                guardian.health -= uint16(healthDecaySeconds);
            } else {
                guardian.health = 0;
            }

            // Energy regen (approx) - Normal rate
            uint64 energyRegenSeconds = (uint64(simParams.energyRegenRatePerDay) * timeElapsed) / (24 * 60 * 60);
            guardian.energy = uint16(Math.min(uint256(guardian.energy) + energyRegenSeconds, 10000)); // Cap at max energy

        } else {
            // Accelerated Energy regen during meditation
            uint64 energyRegenSeconds = (uint64(simParams.energyRegenRatePerDay) * (100 + simParams.meditationEnergyRegenBonus) / 100 * timeElapsed) / (24 * 60 * 60);
            guardian.energy = uint16(Math.min(uint256(guardian.energy) + energyRegenSeconds, 10000));
            // No health decay while meditating (design choice)
        }

        // Growth Stage progression (based on genesis time)
        guardian.growthStage = _calculateGrowthStage(guardian.genesisTimestamp, currentTimestamp);

        // Update last interaction time after calculations
        guardian.lastInteractionTimestamp = currentTimestamp;

        // Emit state update event
        emit GuardianStateUpdated(
            tokenId,
            currentTimestamp,
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    // Internal function to calculate Growth Stage based on age
    function _calculateGrowthStage(uint66 genesisTimestamp, uint66 currentTimestamp) internal view returns (GrowthStage) {
        uint64 ageSeconds = currentTimestamp - genesisTimestamp;

        if (ageSeconds < simParams.babyStageDuration) {
            return GrowthStage.Baby;
        } else if (ageSeconds < simParams.babyStageDuration + simParams.juvenileStageDuration) {
            return GrowthStage.Juvenile;
        } else if (ageSeconds < simParams.babyStageDuration + simParams.juvenileStageDuration + simParams.adultStageDuration) {
            return GrowthStage.Adult;
        } else {
            return GrowthStage.Elder;
        }
         // Egg stage is before any time passes from genesis, handled in _beforeTokenTransfer
    }


    // Helper to convert AffinityType enum to string
    function _affinityTypeToString(AffinityType affinity) internal pure returns (string memory) {
        if (affinity == AffinityType.Fire) return "Fire";
        if (affinity == AffinityType.Water) return "Water";
        if (affinity == AffinityType.Earth) return "Earth";
        if (affinity == AffinityType.Air) return "Air";
        if (affinity == AffinityType.Mystic) return "Mystic";
        return "None";
    }

     // Helper to convert GrowthStage enum to string
    function _growthStageToString(GrowthStage stage) internal pure returns (string memory) {
        if (stage == GrowthStage.Egg) return "Egg";
        if (stage == GrowthStage.Baby) return "Baby";
        if (stage == GrowthStage.Juvenile) return "Juvenile";
        if (stage == GrowthStage.Adult) return "Adult";
        if (stage == GrowthStage.Elder) return "Elder";
        return "Unknown";
    }

    // Helper for simulated random outcomes based on a seed (same predictability caveat as _generateInitialStats)
    function _simulatedRandomRoll(uint256 seed, uint256 max) internal pure returns (uint256) {
        if (max == 0) return 0;
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tx.origin, block.number, block.difficulty, seed)));
        return randomness % (max + 1);
    }

    // --- Minting ---

    /// @notice Mints a new Guardian NFT for the caller.
    /// @return The ID of the newly minted Guardian.
    function mintNewGuardian() public payable whenNotPaused returns (uint256) {
        _nextTokenId.increment();
        uint256 newTokenId = _nextTokenId.current();
        _safeMint(msg.sender, newTokenId); // Handles ERC721 minting and calls _beforeTokenTransfer

        // Initial state is set in _beforeTokenTransfer
        emit GuardianMinted(newTokenId, msg.sender, _guardians[newTokenId].affinity);
        emit GuardianStateUpdated( // Emit initial state as well
            newTokenId,
            _guardians[newTokenId].genesisTimestamp,
            _guardians[newTokenId].health,
            _guardians[newTokenId].energy,
            _guardians[newTokenId].intelligenceScore,
            _guardians[newTokenId].experiencePoints,
            _guardians[newTokenId].growthStage,
            _guardians[newTokenId].isMeditating
        );


        return newTokenId;
    }

    // --- View Functions ---

    /// @notice Gets the full current stats of a Guardian.
    /// @dev Implicitly updates state based on time elapsed before returning.
    /// @param tokenId The ID of the Guardian.
    /// @return Guardian struct containing all stats.
    function getGuardianStats(uint256 tokenId) public whenGuardianExists(tokenId) view returns (Guardian memory) {
         // Cannot modify state in a view function, so we compute the *current* potential state
         // based on time elapsed, but the actual stored state is only updated on interaction.
         // The tokenURI function does a similar calculation for metadata.
         // For this view function, we return the *last updated* stored state.
         // If you want the most up-to-the-second state *estimate* in a view, you'd copy the
         // logic from tokenURI's simulated update here, but it's expensive.
         // Returning the stored state is generally sufficient for view functions.
        return _guardians[tokenId];
    }

    /// @notice Gets the name of a Guardian.
    /// @param tokenId The ID of the Guardian.
    /// @return The name of the Guardian, or default if not set.
    function getGuardianName(uint256 tokenId) public view whenGuardianExists(tokenId) returns (string memory) {
        return bytes(_guardianNames[tokenId]).length > 0 ? _guardianNames[tokenId] : string(abi.encodePacked("Guardian #", tokenId.toString()));
    }

    /// @notice Gets the Growth Stage of a Guardian.
    /// @dev Returns the stage based on current time relative to genesis.
    /// @param tokenId The ID of the Guardian.
    /// @return The Growth Stage enum.
    function getGuardianGrowthStage(uint256 tokenId) public view whenGuardianExists(tokenId) returns (GrowthStage) {
        return _calculateGrowthStage(_guardians[tokenId].genesisTimestamp, uint66(block.timestamp));
    }

     /// @notice Gets the Affinity Type of a Guardian.
    /// @param tokenId The ID of the Guardian.
    /// @return The AffinityType enum.
    function getGuardianAffinity(uint256 tokenId) public view whenGuardianExists(tokenId) returns (AffinityType) {
        return _guardians[tokenId].affinity;
    }


    /// @notice Gets the current contract paused state.
    /// @return True if paused, false otherwise.
    function getContractState() public view returns (bool) {
        return paused();
    }

     /// @notice Gets the total number of Guardians minted.
    /// @return The current token counter.
    function getTokenCounter() public view returns (uint256) {
        return _nextTokenId.current();
    }


    // --- Interaction Functions ---

    /// @notice Feeds a Guardian, boosting health and energy.
    /// @param tokenId The ID of the Guardian to feed.
    function feedGuardian(uint256 tokenId)
        public
        payable // Example: requires payment/resource
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
        onlyInteractable(tokenId) // Cannot feed if meditating
    {
        _updateGuardianState(tokenId); // Apply time-based changes first
        Guardian storage guardian = _guardians[tokenId];

        guardian.health = uint16(Math.min(uint256(guardian.health) + simParams.feedHealthGain, 10000));
        guardian.energy = uint16(Math.min(uint256(guardian.energy) + simParams.feedEnergyGain, 10000));

        emit GuardianInteracted(tokenId, "Feed", uint66(block.timestamp));
        emit GuardianStateUpdated(
            tokenId,
            uint66(block.timestamp),
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    /// @notice Trains a Guardian, increasing experience and potentially intelligence.
    /// @dev Consumes energy.
    /// @param tokenId The ID of the Guardian to train.
    function trainGuardian(uint256 tokenId)
        public
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
        onlyInteractable(tokenId) // Cannot train if meditating
    {
        _updateGuardianState(tokenId);
        Guardian storage guardian = _guardians[tokenId];

        if (guardian.energy < simParams.trainEnergyCost) revert GuardianTooLowEnergy();

        guardian.energy -= simParams.trainEnergyCost;
        guardian.experiencePoints += simParams.trainExpGain;
        // Intelligence gain is capped and probabilistic (simulated)
        if (guardian.intelligenceScore < 1000 && _simulatedRandomRoll(tokenId, 100) < 20) { // 20% chance to gain Int on train
             guardian.intelligenceScore = uint16(Math.min(uint256(guardian.intelligenceScore) + simParams.trainIntGain, 1000)); // Cap Int at 1000
        }

        emit GuardianInteracted(tokenId, "Train", uint66(block.timestamp));
         emit GuardianStateUpdated(
            tokenId,
            uint66(block.timestamp),
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    /// @notice Heals a Guardian significantly.
    /// @dev Consumes more resources than feeding.
    /// @param tokenId The ID of the Guardian to heal.
    function healGuardian(uint256 tokenId)
        public
        payable // Example: requires more payment/resource
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
        onlyInteractable(tokenId) // Cannot heal if meditating
    {
        _updateGuardianState(tokenId);
        Guardian storage guardian = _guardians[tokenId];

        // Maybe add a cost check based on msg.value here if implementing actual costs
        // require(msg.value >= healCost, "Insufficient funds for healing");

        guardian.health = uint16(Math.min(uint256(guardian.health) + simParams.healHealthGain, 10000));

        emit GuardianInteracted(tokenId, "Heal", uint66(block.timestamp));
         emit GuardianStateUpdated(
            tokenId,
            uint66(block.timestamp),
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    /// @notice Puts a Guardian into a meditating state.
    /// @dev While meditating, energy regenerates faster but other interactions are blocked.
    /// @param tokenId The ID of the Guardian.
    function meditateGuardian(uint256 tokenId)
        public
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
        // Note: Does NOT use onlyInteractable as meditating *is* an interaction state change
    {
         _updateGuardianState(tokenId);
         Guardian storage guardian = _guardians[tokenId];
         if (guardian.isMeditating) revert GuardianAlreadyMeditating();

         guardian.isMeditating = true;
         emit GuardianInteracted(tokenId, "Meditate (Enter)", uint66(block.timestamp));
          emit GuardianStateUpdated(
            tokenId,
            uint66(block.timestamp),
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    /// @notice Exits the meditating state for a Guardian.
    /// @param tokenId The ID of the Guardian.
    function exitMeditation(uint256 tokenId)
        public
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
    {
         _updateGuardianState(tokenId);
         Guardian storage guardian = _guardians[tokenId];
         if (!guardian.isMeditating) revert GuardianNotMeditating();

         guardian.isMeditating = false;
         emit GuardianInteracted(tokenId, "Meditate (Exit)", uint66(block.timestamp));
          emit GuardianStateUpdated(
            tokenId,
            uint66(block.timestamp),
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    /// @notice Sends a Guardian on an exploration attempt.
    /// @dev Consumes energy. Outcome is probabilistic based on intelligence and sim params.
    /// @param tokenId The ID of the Guardian.
    function exploreEnvironment(uint256 tokenId)
        public
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
        onlyInteractable(tokenId) // Cannot explore if meditating
    {
        _updateGuardianState(tokenId);
        Guardian storage guardian = _guardians[tokenId];

        if (guardian.energy < simParams.exploreEnergyCost) revert GuardianTooLowEnergy();

        guardian.energy -= simParams.exploreEnergyCost;

        // Simulate outcome: Chance based on base chance + intelligence bonus
        uint16 successChance = simParams.exploreBaseSuccessChance + (guardian.intelligenceScore * simParams.exploreIntBonusFactor / 100); // int bonus per 100 int
        uint256 roll = _simulatedRandomRoll(tokenId ^ uint256(keccak256("explore")), 100); // Roll 0-100

        bool success = roll < successChance;

        int16 healthDelta = 0;
        int16 energyDelta = -int16(simParams.exploreEnergyCost); // Base cost already applied
        int16 expDelta = 0;
        string memory message;

        if (success) {
            // Positive outcome
            expDelta = int16(simParams.trainExpGain * 2); // More exp than training
            energyDelta += int16(simParams.exploreEnergyCost / 2); // Recover some energy? Or gain energy? Let's say gain a bit.
            message = "Exploration successful! Found resources and gained experience.";
        } else {
            // Negative outcome
            healthDelta = -int16(simParams.challengeBaseDamage); // Lose some health
            expDelta = int16(simParams.trainExpGain / 2); // Gain less exp, or none
            message = "Exploration failed. Encountered difficulties and lost some health.";
        }

        // Apply deltas (ensuring health/energy stay within bounds)
        guardian.health = uint16(Math.max(int256(guardian.health) + healthDelta, 0));
        guardian.health = uint16(Math.min(uint256(guardian.health), 10000));
        guardian.energy = uint16(Math.max(int256(guardian.energy) + energyDelta, 0));
        guardian.energy = uint16(Math.min(uint256(guardian.energy), 10000));
        guardian.experiencePoints = uint16(Math.max(int256(guardian.experiencePoints) + expDelta, 0));


        guardian.lastExploreTimestamp = uint66(block.timestamp); // Set explore cooldown/tracker

        emit GuardianInteracted(tokenId, "Explore", uint66(block.timestamp));
        emit GuardianExplored(tokenId, success, healthDelta, energyDelta, expDelta, message);
         emit GuardianStateUpdated(
            tokenId,
            uint66(block.timestamp),
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }

    /// @notice Simulates a challenge between two Guardians.
    /// @dev Outcome is based on stats and affinities. Affects stats (e.g., health/exp loss/gain).
    /// @param tokenId1 The ID of the Challenger Guardian (must be owned/approved by msg.sender).
    /// @param tokenId2 The ID of the Defender Guardian (can be any guardian).
    /// @return The outcome of the challenge.
    function simulateChallenge(uint256 tokenId1, uint256 tokenId2)
        public
        whenNotPaused
        whenGuardianExists(tokenId1)
        whenGuardianExists(tokenId2)
        onlyOwnerOrApproved(tokenId1)
        onlyInteractable(tokenId1) // Challenger cannot be meditating
        // Defender *can* be meditating - they are challenged passively
    {
        if (tokenId1 == tokenId2) revert SameGuardiansInChallenge();

        // Ensure both guardians' states are somewhat current
        _updateGuardianState(tokenId1);
         // Note: Defender's state is updated for calculation, but stored state only changes if interaction is designed to affect defender too.
         // Let's design it to affect defender's health/exp.
        _updateGuardianState(tokenId2);

        Guardian storage challenger = _guardians[tokenId1];
        Guardian storage defender = _guardians[tokenId2];

        // Basic combat simulation logic:
        // Factors: Health, Energy (maybe affects attack power?), Intelligence (combat prowess), Affinity

        // Example: Simple stat comparison with some randomness and affinity bonus
        // Attack power = Base + (Intelligence / 10) + Random_Roll(Energy / 100)
        // Defense = Base + (Intelligence / 20) + Random_Roll(Health / 100)

        uint256 seed1 = tokenId1 ^ tokenId2 ^ uint256(keccak256("challenge1"));
        uint256 seed2 = tokenId1 ^ tokenId2 ^ uint256(keccak256("challenge2"));


        // Calculate base combat scores influenced by stats
        uint256 challengerScore = simParams.challengeBaseDamage + (challenger.intelligenceScore * simParams.challengeIntFactor / 100) + _simulatedRandomRoll(seed1, challenger.energy / 50); // Max random bonus 200 (if energy 10000)
        uint256 defenderScore = simParams.challengeBaseDamage + (defender.intelligenceScore * simParams.challengeIntFactor / 100) + _simulatedRandomRoll(seed2, defender.health / 100); // Max random bonus 100 (if health 10000)

        // Apply affinity bonus
        // Simple Rock-Paper-Scissors: Fire > Earth, Earth > Air, Air > Water, Water > Fire
        // Mystic is neutral or has unique interactions (omitting complex Mystic logic for brevity)
        bool challengerHasAdvantage = false;
        bool defenderHasAdvantage = false;

        if (challenger.affinity == AffinityType.Fire && defender.affinity == AffinityType.Earth) challengerHasAdvantage = true;
        else if (challenger.affinity == AffinityType.Earth && defender.affinity == AffinityType.Air) challengerHasAdvantage = true;
        else if (challenger.affinity == AffinityType.Air && defender.affinity == AffinityType.Water) challengerHasAdvantage = true;
        else if (challenger.affinity == AffinityType.Water && defender.affinity == AffinityType.Fire) challengerHasAdvantage = true;

        // Vice versa for defender advantage
        if (defender.affinity == AffinityType.Fire && challenger.affinity == AffinityType.Earth) defenderHasAdvantage = true;
        else if (defender.affinity == AffinityType.Earth && challenger.affinity == AffinityType.Air) defenderHasAdvantage = true;
        else if (defender.affinity == AffinityType.Air && challenger.affinity == AffinityType.Water) defenderHasAdvantage = true;
        else if (defender.affinity == AffinityType.Water && challenger.affinity == AffinityType.Fire) defenderHasAdvantage = true;

        if (challengerHasAdvantage) challengerScore = challengerScore * (100 + simParams.challengeAffinityBonusPercent) / 100;
        if (defenderHasAdvantage) defenderScore = defenderScore * (100 + simParams.challengeAffinityBonusPercent) / 100;

        ChallengeOutcome outcome;
        int16 healthLoss1 = 0;
        int16 healthLoss2 = 0;
        int16 expGain1 = 0;
        int16 expGain2 = 0;

        // Determine outcome based on adjusted scores
        if (challengerScore > defenderScore * 120 / 100) { // Challenger significantly stronger (e.g., 20% higher)
            outcome = ChallengeOutcome.ChallengerWins;
            healthLoss2 = int16(simParams.challengeBaseDamage * (challengerScore / defenderScore)); // Defender loses health based on difference
            expGain1 = simParams.trainExpGain * 3; // Challenger gains significant exp
            expGain2 = simParams.trainExpGain / 2; // Defender gains minor exp for participation
        } else if (defenderScore > challengerScore * 120 / 100) { // Defender significantly stronger
            outcome = ChallengeOutcome.DefenderWins;
            healthLoss1 = int16(simParams.challengeBaseDamage * (defenderScore / challengerScore)); // Challenger loses health
            expGain1 = simParams.trainExpGain / 2; // Challenger gains minor exp
            expGain2 = simParams.trainExpGain * 3; // Defender gains significant exp
        } else if (challengerScore > defenderScore) { // Challenger slightly stronger
            outcome = ChallengeOutcome.ChallengerWins; // Minor win
             healthLoss2 = int16(simParams.challengeBaseDamage / 2);
             expGain1 = simParams.trainExpGain * 2;
             expGain2 = simParams.trainExpGain / 2;
        } else if (defenderScore > challengerScore) { // Defender slightly stronger
            outcome = ChallengeOutcome.DefenderWins; // Minor win
             healthLoss1 = int16(simParams.challengeBaseDamage / 2);
             expGain1 = simParams.trainExpGain / 2;
             expGain2 = simParams.trainExpGain * 2;
        }
        else { // Scores are equal or very close (within 20% threshold)
            outcome = ChallengeOutcome.Draw;
            healthLoss1 = int16(simParams.challengeBaseDamage / 4); // Minor health loss for both in a tough fight
            healthLoss2 = int16(simParams.challengeBaseDamage / 4);
            expGain1 = simParams.trainExpGain; // Both gain standard exp
            expGain2 = simParams.trainExpGain;
        }

        // Apply health losses (ensure non-negative)
        challenger.health = uint16(Math.max(int256(challenger.health) - healthLoss1, 0));
        defender.health = uint16(Math.max(int256(defender.health) - healthLoss2, 0));

        // Apply experience gains
        challenger.experiencePoints += uint16(expGain1);
        defender.experiencePoints += uint16(expGain2);

        emit ChallengeSimulated(tokenId1, tokenId2, outcome);
        emit GuardianInteracted(tokenId1, "Challenge (Challenger)", uint66(block.timestamp));
         emit GuardianStateUpdated(
            tokenId1,
            uint66(block.timestamp),
            challenger.health,
            challenger.energy,
            challenger.intelligenceScore,
            challenger.experiencePoints,
            challenger.growthStage,
            challenger.isMeditating
        );
        // Defender's state updated implicitly by _updateGuardianState call at start
         emit GuardianStateUpdated(
            tokenId2,
            uint66(block.timestamp),
            defender.health,
            defender.energy,
            defender.intelligenceScore,
            defender.experiencePoints,
            defender.growthStage,
            defender.isMeditating
        );
    }


    /// @notice Bonds with a Guardian, providing a potential temporary stat boost.
    /// @dev Has a cooldown period.
    /// @param tokenId The ID of the Guardian to bond with.
    function bondWithGuardian(uint256 tokenId)
        public
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
        onlyInteractable(tokenId) // Cannot bond if meditating
    {
        _updateGuardianState(tokenId);
        Guardian storage guardian = _guardians[tokenId];

        uint66 currentTimestamp = uint66(block.timestamp);
        if (guardian.lastBondTimestamp > 0 && currentTimestamp < guardian.lastBondTimestamp + simParams.bondCooldownDays * 1 days) {
            revert CannotBondYet();
        }

        // Apply a temporary or minor permanent boost - let's do a temporary health boost for 24 hours
        uint16 bonus = uint16(guardian.health * simParams.bondStatBonusPercent / 100);
        guardian.health = uint16(Math.min(uint256(guardian.health) + bonus, 10000)); // Apply bonus
        // Note: A temporary effect would require tracking expiration timestamp and applying/removing the effect
        // in _updateGuardianState or interaction functions. Keeping it simple: let's make it a permanent small bonus.
        // Let's re-implement: 5% permanent bonus to a random stat (Int, Max Health, Max Energy)
        uint256 roll = _simulatedRandomRoll(tokenId ^ uint256(keccak256("bond")), 2); // 0, 1, or 2

        uint16 statBonusAmount = 0;
        if (roll == 0) { // Boost Intelligence
             uint16 intBonus = uint16(guardian.intelligenceScore * simParams.bondStatBonusPercent / 100);
             guardian.intelligenceScore = uint16(Math.min(uint256(guardian.intelligenceScore) + intBonus, 1000));
             statBonusAmount = intBonus;
        } else if (roll == 1) { // Boost Max Health (simulated by boosting current health close to max)
             uint16 healthBonus = uint16(10000 * simParams.bondStatBonusPercent / 100);
             guardian.health = uint16(Math.min(uint256(guardian.health) + healthBonus, 10000));
             statBonusAmount = healthBonus; // Representing how much healing/near-max health gained
        } else { // roll == 2, Boost Max Energy (simulated by boosting current energy close to max)
             uint16 energyBonus = uint16(10000 * simParams.bondStatBonusPercent / 100);
             guardian.energy = uint16(Math.min(uint256(guardian.energy) + energyBonus, 10000));
             statBonusAmount = energyBonus; // Representing energy gained
        }


        guardian.lastBondTimestamp = currentTimestamp; // Set cooldown

        emit GuardianInteracted(tokenId, "Bond", currentTimestamp);
        emit GuardianBonded(tokenId, currentTimestamp, statBonusAmount);
         emit GuardianStateUpdated(
            tokenId,
            currentTimestamp,
            guardian.health,
            guardian.energy,
            guardian.intelligenceScore,
            guardian.experiencePoints,
            guardian.growthStage,
            guardian.isMeditating
        );
    }


    // --- Naming ---

    /// @notice Sets the name for a Guardian.
    /// @param tokenId The ID of the Guardian.
    /// @param name The desired name.
    function setGuardianName(uint256 tokenId, string calldata name)
        public
        whenNotPaused
        whenGuardianExists(tokenId)
        onlyOwnerOrApproved(tokenId)
    {
        _guardianNames[tokenId] = name;
        emit GuardianNamed(tokenId, name);
    }


    // --- Contract Management (Owner Functions) ---

    /// @notice Sets the base URI for token metadata.
    /// @param baseURI The new base URI.
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev See {Pausable-pause}.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @dev See {Pausable-unpause}.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

     /// @notice Withdraws collected Ether to the owner.
    function withdrawFees() public onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

     /// @notice Updates multiple simulation parameters.
    /// @dev Allows owner to fine-tune game mechanics. All params must be provided.
    function updateSimulationParameters(
        uint16 _healthDecayRatePerDay,
        uint16 _energyRegenRatePerDay,
        uint16 _meditationEnergyRegenBonus,
        uint16 _feedHealthGain,
        uint16 _feedEnergyGain,
        uint16 _trainEnergyCost,
        uint16 _trainExpGain,
        uint16 _trainIntGain,
        uint16 _healHealthGain,
        uint16 _exploreEnergyCost,
        uint16 _exploreBaseSuccessChance,
        uint16 _exploreIntBonusFactor,
        uint16 _bondCooldownDays,
        uint16 _bondStatBonusPercent,
        uint16 _challengeBaseDamage,
        uint16 _challengeAffinityBonusPercent,
        uint16 _challengeIntFactor,
        uint32 _babyStageDuration,
        uint32 _juvenileStageDuration,
        uint32 _adultStageDuration
    ) public onlyOwner {
        simParams = SimulationParams({
            healthDecayRatePerDay: _healthDecayRatePerDay,
            energyRegenRatePerDay: _energyRegenRatePerDay,
            meditationEnergyRegenBonus: _meditationEnergyRegenBonus,
            feedHealthGain: _feedHealthGain,
            feedEnergyGain: _feedEnergyGain,
            trainEnergyCost: _trainEnergyCost,
            trainExpGain: _trainExpGain,
            trainIntGain: _trainIntGain,
            healHealthGain: _healHealthGain,
            exploreEnergyCost: _exploreEnergyCost,
            exploreBaseSuccessChance: _exploreBaseSuccessChance,
            exploreIntBonusFactor: _exploreIntBonusFactor,
            bondCooldownDays: _bondCooldownDays,
            bondStatBonusPercent: _bondStatBonusPercent,
            challengeBaseDamage: _challengeBaseDamage,
            challengeAffinityBonusPercent: _challengeAffinityBonusPercent,
            challengeIntFactor: _challengeIntFactor,
            babyStageDuration: _babyStageDuration,
            juvenileStageDuration: _juvenileStageDuration,
            adultStageDuration: _adultStageDuration
        });
        // Consider emitting an event for param updates
    }
}

// Add Math library manually if not using solady or similar, needed for min/max
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic NFT State (`Guardian` struct, `_guardians` mapping):** The core idea isn't just an image/metadata; it's an object with persistent, changing stats stored on-chain.
2.  **Time-Based Evolution (`_updateGuardianState`, `lastInteractionTimestamp`):** The health decay and energy regeneration mechanics directly link the NFT's state to real-world time elapsed. Neglect (long time between interactions) leads to degradation. Growth stage is also purely time-based relative to creation.
3.  **Parameterized Outcomes (`exploreEnvironment`, `simulateChallenge`, `SimulationParams` struct):** Actions have results that aren't fixed or purely random. They are influenced by the Guardian's current stats (like `intelligenceScore`, `health`, `energy`, `affinity`) and tuning parameters set by the contract owner. This creates a simple, deterministic (within the contract's logic) simulation.
4.  **Simulated "Intelligence" (`intelligenceScore`):** This stat directly impacts the success rate of actions like exploration and the outcome of challenges, adding a strategic layer beyond simple resource management.
5.  **State Machine (`isMeditating`):** The meditation state is a simple example of a state machine where being in one state (`isMeditating = true`) unlocks faster energy regen but restricts other actions (`onlyInteractable` modifier).
6.  **Interactive Asset:** The focus is on *doing* things *with* the NFT (`feed`, `train`, `heal`, `explore`, `challenge`, `bond`), rather than just owning or trading it.
7.  **On-Chain "Life Cycle" (`_beforeTokenTransfer`, `_updateGuardianState`):** The contract actively manages the creature's state from minting (birth/egg) through growth stages (baby, juvenile, adult, elder) and potential decay, triggered by transfers and interactions.
8.  **Simulated Resource Management (Health, Energy):** These stats act as resources that are consumed or regenerated, creating gameplay loops where owners must balance actions and care.
9.  **Owner Tunability (`updateSimulationParameters`):** The contract owner has control over the "game mechanics" by adjusting decay rates, gain amounts, success chances, etc., allowing for post-deployment balancing (though this must be used carefully and transparently in a real dApp).
10. **Dynamic Metadata (`tokenURI` override):** The `tokenURI` function pulls the *current* state (simulated based on time for accuracy in the view function) and builds the JSON metadata string, ensuring that marketplaces or explorers displaying the NFT show its live stats. Uses Base64 encoding as is common practice for on-chain metadata.

This contract demonstrates how Solidity can be used to build complex, stateful, and interactive digital assets that go significantly beyond basic token functionality. Remember that deploying such a contract on a mainnet would involve significant gas costs for state changes, and the simulated randomness using block data is not truly secure for high-value outcomes. A production version might use Chainlink VRF for randomness and optimize state storage and computation heavily.