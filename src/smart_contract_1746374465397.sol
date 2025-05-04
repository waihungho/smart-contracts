Okay, let's design a smart contract that represents a dynamic, stateful digital entity, maybe a "Programmable Chronicle Shard" or "ChronoShard Guardian". This entity will be an ERC-721 token at its core, but with extensive on-chain attributes, states, and time-based interactions that owner can perform to influence its development.

It will incorporate:
1.  **Stateful NFTs:** NFTs with dynamic attributes that change based on interaction and time.
2.  **Time-Based Mechanics:** Energy regeneration, cooldowns, passive effects based on `block.timestamp`.
3.  **Probabilistic Outcomes:** Actions with outcomes influenced by the Guardian's stats and perhaps a pseudorandom element (using block data for the example, with a note on VRF for production).
4.  **Progression System:** Guardians can "Evolve" based on accumulated activity/energy/stats.
5.  **Global State Influence:** A global contract parameter (`temporalFlux`) affects all Guardians.
6.  **Complex Interactions:** Multiple functions beyond simple transfers, focusing on engaging with the token's state.

This avoids simple token standards, basic staking/lending, or generic marketplaces.

---

## Contract: ChronoShardGuardian

A dynamic, stateful ERC-721 token representing a digital entity ("Guardian") that evolves based on owner interactions, time, and internal state.

**Key Concepts:**
*   **Guardians:** NFTs with unique IDs and a set of dynamic attributes (Stats, Energy, State).
*   **Stats:** Power, Resilience, Agility, Wisdom - influence action outcomes.
*   **ChronoEnergy:** Resource consumed by actions, regenerates over time.
*   **GuardianState:** Current status (Idle, Synchronizing, Resting, Empowered, etc.) influencing available actions and energy regen.
*   **Chronosync:** The primary action consuming Energy, yielding potential rewards (stat boosts, resources).
*   **Evolution:** A major progression milestone triggered by reaching certain criteria.
*   **TemporalFlux:** A global contract state parameter affecting all Guardians.

---

### Function Summary:

**ERC-721 Standard Functions (Core):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
3.  `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific token.
4.  `getApproved(uint256 tokenId)`: Gets the approved address for a single token.
5.  `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all tokens of an owner.
6.  `isApprovedForAll(address owner, address operator)`: Checks if an address is an operator for another address.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token from one owner to another (internal use).
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token, checking receiver compatibility.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers a token with data.

**Guardian Creation & Info:**
10. `mintInitialGuardian()`: Admin-only function to mint a new Guardian token with base stats.
11. `getGuardianDetails(uint256 tokenId)`: Returns comprehensive details of a Guardian (stats, state, energy, etc.).
12. `getGuardianState(uint256 tokenId)`: Returns only the current state of a Guardian.
13. `getGuardianEnergy(uint256 tokenId)`: Returns the current and maximum ChronoEnergy of a Guardian.
14. `getGuardianStats(uint256 tokenId)`: Returns the current Power, Resilience, Agility, and Wisdom stats.
15. `getTokenURI(uint256 tokenId)`: Returns the metadata URI for a Guardian token.
16. `getCurrentTokenIdCounter()`: Returns the total number of Guardians minted.
17. `getGuardianCount()`: Alias for `getCurrentTokenIdCounter()`.

**Core Guardian Interactions (Owner Only):**
18. `claimChronoEnergy(uint256 tokenId)`: Allows the owner to claim accumulated passive ChronoEnergy based on time and state.
19. `performChronosync(uint256 tokenId)`: Initiates the primary action, consuming energy, potentially changing stats/state, and triggering events. Outcome is influenced by stats and temporal flux.
20. `restGuardian(uint256 tokenId)`: Puts the Guardian into a `Resting` state, potentially affecting energy gain rate or other parameters. Requires the Guardian to be in a non-active state.
21. `influenceGuardianStats(uint256 tokenId, uint8 statIndex)`: Allows the owner to spend a resource (e.g., Energy, or contract native token) to attempt boosting a specific stat. Outcome is probabilistic, influenced by the Wisdom stat.
22. `checkEvolutionPotential(uint256 tokenId)`: Checks if a Guardian meets the criteria (energy accumulated, stats reached, state) to trigger an evolution.
23. `triggerEvolution(uint256 tokenId)`: If the Guardian is ready, this function applies evolution benefits (stat boosts, state change, unlocking new abilities/higher caps). Consumes the evolution potential.

**Global State & Admin:**
24. `updateTemporalFlux(uint8 newFluxLevel)`: Admin-only function to change the global `temporalFluxLevel`, affecting all Guardian interactions.
25. `getCurrentTemporalFlux()`: Returns the current global temporal flux level.
26. `setBaseURI(string memory newBaseURI)`: Admin-only function to update the base URI for token metadata.
27. `setEnergyParameters(uint256 maxEnergy, uint256 baseGainRate, uint256 syncCost)`: Admin-only function to adjust energy mechanics.
28. `setEvolutionThreshold(uint256 thresholdIndex, uint256 requiredEnergy)`: Admin-only function to configure evolution requirements.
29. `setInfluenceParameters(uint256 costPerAttempt, uint8 wisdomInfluenceFactor)`: Admin-only function to configure stat influence costs and effects.
30. `withdrawBalance()`: Admin-only function to withdraw any native token held by the contract (e.g., from influence attempts).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title ChronoShardGuardian
/// @dev A dynamic, stateful ERC-721 token representing a digital entity that evolves
///      based on owner interactions, time, and internal state.
contract ChronoShardGuardian is IERC721, IERC721Receiver {
    using Counters for Counters.Counter;
    using Address for address;

    // --- State Variables ---

    // Admin address - likely the deployer or a separate multisig
    address public admin;

    // Token Counter
    Counters.Counter private _tokenIds;

    // ERC721 Core Mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ERC721 Metadata
    string private _name = "ChronoShardGuardian";
    string private _symbol = "CSG";
    string private _baseTokenURI;

    // Guardian Specific Data
    enum GuardianState { Idle, Synchronizing, Resting, Empowered, Evolved }
    enum StatIndex { Power, Resilience, Agility, Wisdom }

    struct GuardianStats {
        uint8 power;      // Influences Chronosync outcome, damage potential (future)
        uint8 resilience; // Influences energy recovery, defense potential (future)
        uint8 agility;    // Influences action speed, evasion potential (future)
        uint8 wisdom;     // Influences probabilistic stat influence, evolution potential unlock
    }

    struct Guardian {
        GuardianStats stats;
        uint256 chronoEnergy;
        GuardianState state;
        uint256 lastInteractionTime; // Used for energy calculations, cooldowns
        uint256 accumulatedChronoEnergy; // Total energy gained/spent over time for evolution checks
        uint8 evolutionLevel;        // Tracks evolution stage
    }

    mapping(uint256 => Guardian) private _guardians; // tokenId => Guardian data

    // Global State Parameters
    uint8 public temporalFluxLevel; // Affects interaction outcomes, energy gain, etc. (e.g., 1-100)

    // Configuration Parameters (Admin settable)
    uint256 public maxChronoEnergy = 1000;
    uint256 public baseChronoEnergyGainRate = 10; // Energy per unit of time (e.g., per hour)
    uint256 public chronosyncEnergyCost = 100;
    uint256[] public evolutionThresholds; // Accumulated energy needed for evolution levels
    uint256 public influenceAttemptCost = 0.01 ether; // Cost in native token to attempt stat influence
    uint8 public wisdomInfluenceFactor = 5; // How much Wisdom affects influence success chance

    // --- Events ---

    event GuardianMinted(uint256 indexed tokenId, address indexed owner, GuardianStats initialStats);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ChronoEnergyClaimed(uint256 indexed tokenId, uint256 claimedAmount, uint256 newEnergy);
    event ChronosyncPerformed(uint256 indexed tokenId, GuardianState newState, uint256 energySpent, string outcomeDescription);
    event GuardianRested(uint256 indexed tokenId, uint256 timeRested);
    event StatsInfluenced(uint256 indexed tokenId, StatIndex indexed statIndex, uint8 oldStat, uint8 newStat, bool success);
    event EvolutionPotentialChecked(uint256 indexed tokenId, bool isReady, uint256 currentAccumulatedEnergy);
    event EvolutionTriggered(uint256 indexed tokenId, uint8 newEvolutionLevel, GuardianStats boostedStats);
    event TemporalFluxUpdated(uint8 oldFlux, uint8 newFlux);

    event BaseURIUpdated(string newBaseURI);
    event EnergyParametersUpdated(uint256 maxEnergy, uint256 baseGainRate, uint256 syncCost);
    event EvolutionThresholdUpdated(uint256 indexed thresholdIndex, uint256 requiredEnergy);
    event InfluenceParametersUpdated(uint256 costPerAttempt, uint8 wisdomInfluenceFactor);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized: Admin only");
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Unauthorized: Not token owner or approved");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        // Set some initial evolution thresholds (e.g., Energy required for Lv 1, Lv 2, etc.)
        evolutionThresholds = [5000, 20000, 50000]; // Example values
        temporalFluxLevel = 50; // Default flux level
    }

    // --- ERC721 Standard Implementations ---

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // ERC721 Internal Helpers
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Update Guardian state owner (redundant with _owners but good practice for the struct)
        _guardians[tokenId].lastInteractionTime = block.timestamp; // Reset interaction time on transfer

        emit Transfer(from, to, tokenId);
    }

     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(to.isContract(), "ERC721: transfer to non-ERC721Receiver implementer");
        require(
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
            IERC721Receiver.onERC721Received.selector,
            "ERC721: ERC721Receiver rejected transfer"
        );
    }

    // --- Guardian Creation & Info ---

    /// @dev Admin function to mint a new Guardian token.
    /// @param initialStats The base stats for the new Guardian.
    function mintInitialGuardian(GuardianStats memory initialStats) public onlyAdmin {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        address receiver = msg.sender; // Mint to admin by default, they can transfer

        require(receiver != address(0), "Mint to zero address");
        require(!_exists(newTokenId), "Token already exists");

        _guardians[newTokenId] = Guardian({
            stats: initialStats,
            chronoEnergy: 0,
            state: GuardianState.Idle,
            lastInteractionTime: block.timestamp,
            accumulatedChronoEnergy: 0,
            evolutionLevel: 0
        });

        _owners[newTokenId] = receiver;
        _balances[receiver] += 1;

        emit GuardianMinted(newTokenId, receiver, initialStats);
        emit Transfer(address(0), receiver, newTokenId);
    }

    /// @dev Returns comprehensive details of a Guardian.
    /// @param tokenId The ID of the Guardian token.
    /// @return The Guardian struct.
    function getGuardianDetails(uint256 tokenId) public view returns (Guardian memory) {
        require(_exists(tokenId), "Guardian does not exist");
        return _guardians[tokenId];
    }

    /// @dev Returns the current state of a Guardian.
    /// @param tokenId The ID of the Guardian token.
    /// @return The GuardianState enum value.
    function getGuardianState(uint256 tokenId) public view returns (GuardianState) {
        require(_exists(tokenId), "Guardian does not exist");
        return _guardians[tokenId].state;
    }

    /// @dev Returns the current and maximum ChronoEnergy of a Guardian.
    /// @param tokenId The ID of the Guardian token.
    /// @return currentEnergy The current ChronoEnergy.
    /// @return max The maximum possible ChronoEnergy.
    function getGuardianEnergy(uint256 tokenId) public view returns (uint256 currentEnergy, uint256 max) {
        require(_exists(tokenId), "Guardian does not exist");
        return (_guardians[tokenId].chronoEnergy, maxChronoEnergy);
    }

    /// @dev Returns the current stats (Power, Resilience, Agility, Wisdom) of a Guardian.
    /// @param tokenId The ID of the Guardian token.
    /// @return stats The GuardianStats struct.
    function getGuardianStats(uint256 tokenId) public view returns (GuardianStats memory stats) {
        require(_exists(tokenId), "Guardian does not exist");
        return _guardians[tokenId].stats;
    }

    /// @dev Returns the metadata URI for a Guardian token.
    /// @param tokenId The ID of the Guardian token.
    /// @return The token URI string.
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    /// @dev Returns the total number of Guardians minted.
    /// @return The current token ID counter value.
    function getCurrentTokenIdCounter() public view returns (uint256) {
        return _tokenIds.current();
    }

    /// @dev Returns the total number of Guardians.
    /// @return The current token ID counter value.
    function getGuardianCount() public view returns (uint256) {
        return _tokenIds.current();
    }


    // --- Core Guardian Interactions ---

    /// @dev Allows the owner to claim accumulated passive ChronoEnergy.
    ///      Energy generation rate is based on time since last interaction and Guardian state.
    /// @param tokenId The ID of the Guardian token.
    function claimChronoEnergy(uint256 tokenId) public onlyOwnerOf(tokenId) {
        Guardian storage guardian = _guardians[tokenId];
        uint256 timeElapsed = block.timestamp - guardian.lastInteractionTime;

        uint256 energyGain = (timeElapsed * baseChronoEnergyGainRate) / (1 hours); // Example: gain rate per hour

        // State influence on energy gain (example)
        if (guardian.state == GuardianState.Resting) {
             energyGain = (energyGain * 150) / 100; // 50% bonus in Resting state
        } else if (guardian.state == GuardianState.Synchronizing) {
             energyGain = (energyGain * 50) / 100; // 50% penalty while Synchronizing
        }
        // Idle, Empowered, Evolved could have other multipliers

        uint256 energyBefore = guardian.chronoEnergy;
        uint256 energyToAdd = Math.min(energyGain, maxChronoEnergy - guardian.chronoEnergy);

        guardian.chronoEnergy += energyToAdd;
        guardian.lastInteractionTime = block.timestamp; // Reset timer

        // Accumulate total energy gained (for evolution)
        guardian.accumulatedChronoEnergy += energyToAdd;

        emit ChronoEnergyClaimed(tokenId, energyToAdd, guardian.chronoEnergy);
    }

    /// @dev Initiates the primary action for the Guardian: Chronosync.
    ///      Consumes energy, changes state, and has a probabilistic outcome.
    /// @param tokenId The ID of the Guardian token.
    function performChronosync(uint256 tokenId) public onlyOwnerOf(tokenId) {
        Guardian storage guardian = _guardians[tokenId];

        // Ensure enough energy
        require(guardian.chronoEnergy >= chronosyncEnergyCost, "Insufficient Energy for Chronosync");

        // Ensure valid state for sync
        require(guardian.state == GuardianState.Idle || guardian.state == GuardianState.Empowered, "Guardian not in a state to Sync");

        // Consume energy
        guardian.chronoEnergy -= chronosyncEnergyCost;

        // Change state
        guardian.state = GuardianState.Synchronizing;
        guardian.lastInteractionTime = block.timestamp; // Update last interaction time

        // Determine outcome (Simplified probability for example - use VRF for real dApps!)
        // Outcome influenced by Stats and Temporal Flux
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, guardian.stats.wisdom, temporalFluxLevel)));
        uint256 outcomeRoll = randomSeed % 100; // 0-99

        string memory outcomeDescription;

        // Example Outcome Logic (make this more complex!)
        uint256 effectiveWisdom = guardian.stats.wisdom + (guardian.evolutionLevel * 5); // Wisdom + Evolution bonus
        uint256 successChance = 40 + (effectiveWisdom / 2) + (temporalFluxLevel / 5); // Base + Wisdom + Flux

        if (outcomeRoll < successChance) {
            // Success! Maybe a temporary stat boost or resource gain
            outcomeDescription = "Chronosync Successful! Received a temporary surge.";
            // Example: Grant temporary 'Empowered' state
            guardian.state = GuardianState.Empowered; // Can stay in Empowered for a duration, affects future actions
        } else {
            // Partial success or failure
            outcomeDescription = "Chronosync completed, but yielded uncertain results.";
             // Maybe revert to Idle or go to a 'Fatigued' state (not implemented here, but possible)
             guardian.state = GuardianState.Idle;
        }

        emit ChronosyncPerformed(tokenId, guardian.state, chronosyncEnergyCost, outcomeDescription);
    }

    /// @dev Puts the Guardian into a Resting state.
    ///      Useful for faster energy recovery or unlocking certain actions.
    /// @param tokenId The ID of the Guardian token.
    function restGuardian(uint256 tokenId) public onlyOwnerOf(tokenId) {
        Guardian storage guardian = _guardians[tokenId];
        require(guardian.state != GuardianState.Resting, "Guardian is already Resting");
        require(guardian.state != GuardianState.Synchronizing, "Guardian is busy Synchronizing");

        uint256 timeRested = block.timestamp - guardian.lastInteractionTime; // Time since last action before resting

        guardian.state = GuardianState.Resting;
        guardian.lastInteractionTime = block.timestamp; // Reset timer

        emit GuardianRested(tokenId, timeRested);
    }

    /// @dev Allows the owner to spend resources to attempt boosting a specific stat.
    ///      Probabilistic outcome influenced by the Guardian's Wisdom stat and global flux.
    /// @param tokenId The ID of the Guardian token.
    /// @param statIndex The index of the stat to influence (0=Power, 1=Resilience, 2=Agility, 3=Wisdom).
    function influenceGuardianStats(uint256 tokenId, uint8 statIndex) public payable onlyOwnerOf(tokenId) {
        Guardian storage guardian = _guardians[tokenId];
        require(statIndex <= uint8(StatIndex.Wisdom), "Invalid stat index");
        require(msg.value >= influenceAttemptCost, "Insufficient payment for influence attempt");

        // Admin gets the payment
        (bool successTx, ) = payable(admin).call{value: msg.value}("");
        require(successTx, "Payment transfer failed");

        // Determine outcome (Simplified probability - use VRF for real dApps!)
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, statIndex, guardian.stats.wisdom, temporalFluxLevel)));
        uint256 outcomeRoll = randomSeed % 100; // 0-99

        uint256 effectiveWisdom = guardian.stats.wisdom + (guardian.evolutionLevel * 5);
        uint256 successChance = 30 + (effectiveWisdom * wisdomInfluenceFactor) / 100 + (temporalFluxLevel / 10); // Base + Wisdom influence + Flux influence

        uint8 oldStatValue;
        uint8 newStatValue;
        bool success = false;

        if (outcomeRoll < successChance) {
            // Success! Boost the stat
            success = true;
            if (statIndex == uint8(StatIndex.Power)) {
                oldStatValue = guardian.stats.power;
                if (guardian.stats.power < 100) guardian.stats.power += 1;
                newStatValue = guardian.stats.power;
            } else if (statIndex == uint8(StatIndex.Resilience)) {
                oldStatValue = guardian.stats.resilience;
                if (guardian.stats.resilience < 100) guardian.stats.resilience += 1;
                newStatValue = guardian.stats.resilience;
            } else if (statIndex == uint8(StatIndex.Agility)) {
                oldStatValue = guardian.stats.agility;
                 if (guardian.stats.agility < 100) guardian.stats.agility += 1;
                newStatValue = guardian.stats.agility;
            } else if (statIndex == uint8(StatIndex.Wisdom)) {
                oldStatValue = guardian.stats.wisdom;
                if (guardian.stats.wisdom < 100) guardian.stats.wisdom += 1;
                newStatValue = guardian.stats.wisdom;
            }
             if (oldStatValue == newStatValue) {
                 // Stat was already at max
                 success = false; // Treat as failure for the event/logic
             }
        } else {
             // Failure or no change
             success = false;
              if (statIndex == uint8(StatIndex.Power)) oldStatValue = guardian.stats.power;
              else if (statIndex == uint8(StatIndex.Resilience)) oldStatValue = guardian.stats.resilience;
              else if (statIndex == uint8(StatIndex.Agility)) oldStatValue = guardian.stats.agility;
              else if (statIndex == uint8(StatIndex.Wisdom)) oldStatValue = guardian.stats.wisdom;
             newStatValue = oldStatValue; // Stat doesn't change on failure
        }

        emit StatsInfluenced(tokenId, StatIndex(statIndex), oldStatValue, newStatValue, success);
    }

    /// @dev Checks if a Guardian meets the criteria to trigger an evolution.
    /// @param tokenId The ID of the Guardian token.
    /// @return isReady True if the Guardian is ready for evolution.
    /// @return requiredEnergy The energy required for the next evolution level.
    /// @return currentAccumulatedEnergy The Guardian's accumulated energy.
    function checkEvolutionPotential(uint256 tokenId) public view returns (bool isReady, uint256 requiredEnergy, uint256 currentAccumulatedEnergy) {
        require(_exists(tokenId), "Guardian does not exist");
        Guardian storage guardian = _guardians[tokenId];

        uint8 nextEvolutionLevel = guardian.evolutionLevel + 1;
        if (nextEvolutionLevel > evolutionThresholds.length) {
            // No more evolution levels defined
            return (false, 0, guardian.accumulatedChronoEnergy);
        }

        requiredEnergy = evolutionThresholds[nextEvolutionLevel - 1];
        currentAccumulatedEnergy = guardian.accumulatedChronoEnergy;

        isReady = currentAccumulatedEnergy >= requiredEnergy;

        emit EvolutionPotentialChecked(tokenId, isReady, currentAccumulatedEnergy);

        return (isReady, requiredEnergy, currentAccumulatedEnergy);
    }

    /// @dev Triggers the evolution process for a Guardian if it's ready.
    ///      Applies stat boosts and updates evolution level. Consumes evolution potential.
    /// @param tokenId The ID of the Guardian token.
    function triggerEvolution(uint256 tokenId) public onlyOwnerOf(tokenId) {
         Guardian storage guardian = _guardians[tokenId];

        (bool isReady, uint256 requiredEnergy, ) = checkEvolutionPotential(tokenId);
        require(isReady, "Guardian is not ready for evolution");

        uint8 nextEvolutionLevel = guardian.evolutionLevel + 1;

        // Apply stat boosts (example boosts)
        guardian.stats.power += 5 + (nextEvolutionLevel * 1);
        guardian.stats.resilience += 5 + (nextEvolutionLevel * 1);
        guardian.stats.agility += 5 + (nextEvolutionLevel * 1);
        guardian.stats.wisdom += 5 + (nextEvolutionLevel * 1);

        // Cap stats at 100 (or a higher cap for Evolved states if desired)
        guardian.stats.power = Math.min(guardian.stats.power, 100);
        guardian.stats.resilience = Math.min(guardian.stats.resilience, 100);
        guardian.stats.agility = Math.min(guardian.stats.agility, 100);
        guardian.stats.wisdom = Math.min(guardian.stats.wisdom, 100);

        // Update evolution level
        guardian.evolutionLevel = nextEvolutionLevel;

        // Reset accumulated energy for the *next* evolution, or keep it?
        // Let's reset for the *next* tier requirement
        guardian.accumulatedChronoEnergy -= requiredEnergy; // Or just reset to 0, depending on design

        // Maybe change state permanently or unlock new abilities
        guardian.state = GuardianState.Evolved; // Example state change

        emit EvolutionTriggered(tokenId, guardian.evolutionLevel, guardian.stats);
    }


    // --- Global State & Admin ---

    /// @dev Admin function to update the global temporal flux level.
    ///      This level can influence various interactions for all Guardians.
    /// @param newFluxLevel The new temporal flux level (e.g., 1-100).
    function updateTemporalFlux(uint8 newFluxLevel) public onlyAdmin {
        uint8 oldFlux = temporalFluxLevel;
        temporalFluxLevel = newFluxLevel;
        emit TemporalFluxUpdated(oldFlux, newFluxLevel);
    }

    /// @dev Returns the current global temporal flux level.
    /// @return The current temporal flux level.
    function getCurrentTemporalFlux() public view returns (uint8) {
        return temporalFluxLevel;
    }

    /// @dev Admin function to update the base URI for token metadata.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) public onlyAdmin {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /// @dev Admin function to set energy parameters.
    /// @param max The maximum energy a Guardian can hold.
    /// @param gainRate The base energy gain rate per hour.
    /// @param syncCost The energy cost of a Chronosync.
    function setEnergyParameters(uint256 max, uint256 gainRate, uint256 syncCost) public onlyAdmin {
        maxChronoEnergy = max;
        baseChronoEnergyGainRate = gainRate;
        chronosyncEnergyCost = syncCost;
        emit EnergyParametersUpdated(max, gainRate, syncCost);
    }

    /// @dev Admin function to set the accumulated energy required for a specific evolution level.
    ///      Requires setting thresholds sequentially.
    /// @param thresholdIndex The index of the evolution level (0 for Lv 1, 1 for Lv 2, etc.).
    /// @param requiredEnergy The accumulated energy needed for this level.
    function setEvolutionThreshold(uint256 thresholdIndex, uint256 requiredEnergy) public onlyAdmin {
        require(thresholdIndex < evolutionThresholds.length, "Threshold index out of bounds");
        evolutionThresholds[thresholdIndex] = requiredEnergy;
        emit EvolutionThresholdUpdated(thresholdIndex, requiredEnergy);
    }

    /// @dev Helper function to get a specific evolution threshold.
    /// @param thresholdIndex The index of the evolution level.
    /// @return The required accumulated energy.
    function getEvolutionThreshold(uint256 thresholdIndex) public view returns (uint256) {
        require(thresholdIndex < evolutionThresholds.length, "Threshold index out of bounds");
        return evolutionThresholds[thresholdIndex];
    }


    /// @dev Admin function to set parameters for stat influence attempts.
    /// @param costPerAttempt The native token cost per influence attempt.
    /// @param wisdomFactor How much Wisdom influences the success chance (higher = more influence).
    function setInfluenceParameters(uint256 costPerAttempt, uint8 wisdomFactor) public onlyAdmin {
        influenceAttemptCost = costPerAttempt;
        wisdomInfluenceFactor = wisdomFactor;
        emit InfluenceParametersUpdated(costPerAttempt, wisdomFactor);
    }


    /// @dev Admin function to withdraw native tokens held by the contract.
    function withdrawBalance() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(admin).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(admin, balance);
    }

    // --- Receive/Fallback (Optional, for receiving native tokens) ---
    receive() external payable {}
    fallback() external payable {}

    // --- IERC721Receiver Implementation ---
    /// @inheritdoc IERC721Receiver
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        // This function is called when a token is transferred to this contract.
        // By returning the selector, we indicate that the contract can receive ERC721 tokens.
        // Custom logic could be added here if the contract needs to react to receiving specific tokens.
        return this.onERC721Received.selector;
    }
}

// Simple Math library for min (OpenZeppelin has this in future versions, include here for compatibility)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// Basic Strings utility (OpenZeppelin has this)
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(_HEX_SYMBOLS[uint8(48 + value % 10)]);
            value /= 10;
        }
        return string(buffer);
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Stateful NFTs:** The `Guardian` struct attached to each token ID (`_guardians` mapping) makes these NFTs much more than just ownership pointers. They carry dynamic state (`stats`, `chronoEnergy`, `state`, `lastInteractionTime`, `evolutionLevel`). This is a core concept in gaming, digital collectibles with utility, and virtual worlds on the blockchain.
2.  **Time-Based Energy Mechanics:** The `claimChronoEnergy` function uses `block.timestamp` to calculate passive energy regeneration. This introduces a time-gated resource mechanic common in many games, encouraging regular interaction. The energy gain rate is also influenced by the `GuardianState`, adding strategic depth (e.g., `Resting` gives a bonus).
3.  **Probabilistic Outcomes:** `performChronosync` and `influenceGuardianStats` include logic where the outcome (success/failure, stat changes) is not guaranteed. This outcome is influenced by the Guardian's `Wisdom` stat and the global `temporalFluxLevel`. *Crucially, the example uses `block.timestamp` and `block.difficulty` for pseudorandomness, which is **not secure or unpredictable in a production environment**. A real dApp would integrate with Chainlink VRF or a similar Verifiable Random Function service for truly decentralized and secure randomness.* The code includes comments acknowledging this limitation.
4.  **Progression System (Evolution):** The `checkEvolutionPotential` and `triggerEvolution` functions introduce a clear progression path. Guardians accumulate `accumulatedChronoEnergy` (potentially from claims and syncs) and can reach defined `evolutionThresholds`. Evolution provides significant, permanent stat boosts and potentially unlocks new states or abilities, giving players a long-term goal.
5.  **Global State Influence (`temporalFlux`):** The `updateTemporalFlux` function allows the admin (or potentially a DAO in a more complex version) to change a single variable that affects the mechanics for *all* Guardians (e.g., altering success chances or energy rates). This introduces a global, dynamic element that can be used for seasonal events, balancing, or reacting to external factors.
6.  **Complex Interaction Functions:** Functions like `performChronosync`, `influenceGuardianStats`, `claimChronoEnergy`, `restGuardian`, and `triggerEvolution` go far beyond the standard ERC-721 transfer. They represent specific actions within the contract's defined world, consuming resources, changing internal state, emitting domain-specific events, and influencing future interactions.
7.  **Multiple State Transitions:** Guardians can transition between different `GuardianState` values (`Idle`, `Synchronizing`, `Resting`, `Empowered`, `Evolved`), and function availability or effects can depend on the current state.

The contract includes over 30 functions (well exceeding the 20 minimum), covering standard ERC-721 requirements, detailed view functions for the custom state, core interaction logic, progression mechanics, and administrative controls. The combination of stateful NFTs, time, probabilistic outcomes, and a global influencing state creates a unique and interactive on-chain asset concept.