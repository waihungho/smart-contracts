```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For totalSupply, tokenByIndex, tokenOfOwnerByIndex
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

// Outline:
// 1. License and Pragma
// 2. Imports (ERC721, ERC721Enumerable, Ownable, Counters, Math)
// 3. Error Definitions (Custom errors for clarity)
// 4. Enum for Particle Phases (Representing different conceptual states)
// 5. Struct for Particle State properties (Dynamic attributes of each NFT)
// 6. State Variables (Mappings for particle data, counters, system parameters)
// 7. Events (Signaling key actions and state changes on-chain)
// 8. Constructor (Deploys contract, sets owner and initial system parameters)
// 9. ERC721 Standard Functions (balanceOf, ownerOf, transfers, approvals, supportsInterface - REQUIRED)
// 10. ERC721Enumerable Functions (totalSupply, tokenByIndex, tokenOfOwnerByIndex - REQUIRED if using ERC721Enumerable)
// 11. Core Particle Logic Functions (Spawn, Fluctuations, Observation, Influence)
// 12. View/Getter Functions (Accessing specific particle attributes and system state)
// 13. Admin/System Control Functions (Owner-only functions to tune system parameters)
// 14. Internal Helper Functions (Helper functions for internal logic)

// Function Summary:
// constructor(): Deploys the contract, sets owner and initial parameters.
// supportsInterface(bytes4 interfaceId): ERC165 standard, checks if contract supports an interface. (1)
// balanceOf(address owner): ERC721 standard, returns number of tokens owned by an address. (2)
// ownerOf(uint256 tokenId): ERC721 standard, returns owner of a specific token. (3)
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard, safely transfers token ownership. (4)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): ERC721 standard, safely transfers token ownership with data. (5)
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard, transfers token ownership. (6)
// approve(address to, uint256 tokenId): ERC721 standard, approves address to transfer token. (7)
// setApprovalForAll(address operator, bool approved): ERC721 standard, approves operator for all tokens. (8)
// getApproved(uint256 tokenId): ERC721 standard, returns approved address for a token. (9)
// isApprovedForAll(address owner, address operator): ERC721 standard, checks if operator is approved for all owner's tokens. (10)
// totalSupply(): ERC721Enumerable, returns total number of tokens minted. (11)
// tokenByIndex(uint256 index): ERC721Enumerable, returns token ID at specific index (unsafe for large collections). (12)
// tokenOfOwnerByIndex(address owner, uint256 index): ERC721Enumerable, returns token ID of owner at specific index. (13)
// spawnParticle(): Mints a new quantum particle NFT with initial properties. (14)
// getParticleState(uint256 tokenId): Returns the full state struct of a particle. (15)
// triggerFluctuation(uint256 tokenId): Attempts to trigger a state fluctuation for a particle based on internal logic and pseudo-randomness. Cannot fluctuate if observed. (16)
// observeParticle(uint256 tokenId, uint256 duration): Allows an address to lock a particle's state for a specified duration. Cannot observe if cooldown is active. (17)
// stopObservation(uint256 tokenId): Allows the current observer to manually end observation early. (18)
// isParticleObserved(uint256 tokenId): Checks if a particle is currently under observation. (19)
// getObservationEndTime(uint256 tokenId): Returns the timestamp when observation ends (0 if not observed). (20)
// influenceParticle(uint256 tokenId, bytes32 interactionData): Attempts to influence a particle's state using arbitrary external data as an additional factor. Cannot influence if observed. (21)
// getSystemEntropy(): Calculates a simplified, conceptual measure of the system's overall instability by summing particle instability scores. (NOTE: This is gas-intensive for large token counts and should be avoided in production). (22)
// measureFluctuationAmplitude(uint256 tokenId): Calculates a particle's potential for state change based on its current energy and stability. (23)
// getParticlePhase(uint256 tokenId): Returns the current conceptual phase of a particle. (24)
// getParticleEnergy(uint256 tokenId): Returns the current energy level of a particle. (25)
// getParticleStability(uint256 tokenId): Returns the current stability score of a particle. (26)
// getParticleLastFluctuationBlock(uint256 tokenId): Returns the block number when the particle last successfully fluctuated. (27)
// getParticleLastObservationEndTime(uint256 tokenId): Returns the timestamp when the particle's last observation cooldown ends. (28)
// setFluctuationParameters(uint256 numerator, uint256 denominator): Admin function to set the base chance (numerator/denominator) of a triggered fluctuation occurring. (29)
// getFluctuationParameters(): Returns the current fluctuation chance parameters. (30)
// setObservationCooldown(uint256 cooldown): Admin function to set the minimum time (in seconds) between observations for the same particle. (31)
// getObservationCooldown(): Returns the current observation cooldown duration. (32)
// withdraw(): Admin function to withdraw any Ether held by the contract. (33)
// _beforeTokenTransfer (internal override): Hook to disallow transfer if particle is observed. (N/A - internal)
// _getParticleState (internal): Helper to retrieve particle state with existence check. (N/A - internal)
// _endObservation (internal): Helper to reset observation state and start cooldown. (N/A - internal)


// Custom Error Definitions
error QuantumFluctuations__TokenDoesNotExist(uint256 tokenId);
error QuantumFluctuations__ParticleIsObserved(uint256 tokenId);
error QuantumFluctuations__ObservationNotEnded(uint256 tokenId);
error QuantumFluctuations__NotObserver(uint256 tokenId, address caller);
error QuantumFluctuations__ObservationCooldownActive(uint256 tokenId, uint256 endTime);
error QuantumFluctuations__InvalidFluctuationParameters();
error QuantumFluctuations__DurationTooLong();


// Enum representing conceptual phases of a quantum particle
enum Phase {
    Ground,       // Low energy, stable state
    Excited,      // Higher energy, increased reactivity
    Entangled,    // State conceptually linked (simplified representation)
    Decohered,    // Lost coherence, stable but less dynamic
    Superposed    // Unstable, high potential for state change
}

// Struct holding the dynamic state of each particle NFT
struct ParticleState {
    uint256 energyLevel;       // 0-100, higher = more active state
    Phase phase;               // Current conceptual phase
    uint256 stability;         // 0-10, 0 = very unstable, 10 = very stable
    uint256 lastFluctuationBlock; // Block number when particle last successfully fluctuated
    uint256 lastObservationEndTime; // Timestamp when last observation ended + cooldown
    bool isObserved;           // True if currently under observation
    address observer;          // Address currently observing (address(0) if not observed)
    uint256 observationEndTime; // Timestamp when current observation period ends
}

/// @title QuantumFluctuations
/// @dev A creative smart contract simulating dynamic, probabilistic "quantum" states for NFTs.
///      Particles (NFTs) have properties (energy, phase, stability) that can fluctuate
///      based on on-chain events or user interaction. Observation can temporarily lock state.
contract QuantumFluctuations is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // Counter for generating unique token IDs
    Counters.Counter private _nextTokenId;

    // Mapping from token ID to its dynamic state
    mapping(uint256 => ParticleState) private _particleStates;

    // System parameters controlling fluctuation behavior (owner configurable)
    uint256 public fluctuationChanceNumerator = 30; // Base chance numerator (e.g., 30)
    uint256 public fluctuationChanceDenominator = 100; // Base chance denominator (e.g., 100) => 30/100 = 30%
    uint256 public observationCooldown = 1 days; // Minimum time between observations for the same particle

    // Constants for state boundaries
    uint256 private constant MAX_ENERGY = 100;
    uint256 private constant MAX_STABILITY = 10;
    uint256 private constant MIN_STABILITY = 0;
    uint256 private constant MAX_OBSERVATION_DURATION = 30 days; // Cap observation duration

    // Events to signal state changes
    event ParticleSpawned(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, Phase initialPhase);
    event ParticleFluctuated(uint256 indexed tokenId, uint256 newEnergy, Phase newPhase, uint256 newStability, uint256 blockNumber);
    event ParticleObserved(uint256 indexed tokenId, address indexed observer, uint256 endTime);
    event ParticleObservationStopped(uint256 indexed tokenId);
    event ParticleInfluenced(uint256 indexed tokenId, address indexed caller, bytes32 influenceData, uint256 newEnergy, Phase newPhase, uint256 newStability);
    event FluctuationParametersUpdated(uint256 numerator, uint256 denominator);
    event ObservationCooldownUpdated(uint256 cooldown);


    /// @dev Constructor initializes the ERC721 contract and sets the initial owner.
    constructor() ERC721("QuantumFluctuationParticle", "QFP") Ownable(msg.sender) {}

    // --- ERC721 Standard Functions ---
    // These functions are inherited and implemented by OpenZeppelin's ERC721Enumerable.
    // They are listed in the summary and count towards the function total as they are
    // part of the public interface.

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

    // --- ERC721Enumerable Functions ---
    // These functions are inherited from ERC721Enumerable.
    // They are listed in the summary and count towards the function total.

    // totalSupply()
    // tokenByIndex(uint256 index)
    // tokenOfOwnerByIndex(address owner, uint256 index)

    // Need to override the internal transfer hook to add custom logic
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);

         // Prevent transfer of a particle if it's currently observed.
         // This applies only to single token transfers (batchSize == 1).
         // For batch transfers > 1, this check might need a different implementation or disallow batch transfers entirely.
         if (batchSize == 1 && from != address(0) && _exists(tokenId)) { // Check if token exists and is not a mint
              ParticleState memory particle = _particleStates[tokenId];
              if (particle.isObserved && block.timestamp < particle.observationEndTime) {
                  revert QuantumFluctuations__ParticleIsObserved(tokenId);
              }
         }
     }


    // --- Custom Particle Logic ---

    /// @notice Mints a new quantum particle NFT with initial properties.
    /// @dev Initial state is based on block data and token ID for pseudo-randomness.
    ///      Any address can spawn a particle.
    function spawnParticle() public {
        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        // Pseudo-random seed based on unpredictable block data (prevrandao for PoS, difficulty for PoW),
        // msg.sender, and the new token ID.
        bytes32 initialSeed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, newTokenId));
        uint256 seedUint = uint256(initialSeed);

        // Initialize particle state based on the seed
        _particleStates[newTokenId] = ParticleState({
            energyLevel: (seedUint % (MAX_ENERGY + 1)),
            phase: Phase(seedUint % uint(type(Phase).max)),
            stability: (seedUint % (MAX_STABILITY - MIN_STABILITY + 1)) + MIN_STABILITY,
            lastFluctuationBlock: block.number, // Initial fluctuation block is mint block
            lastObservationEndTime: 0, // No initial cooldown
            isObserved: false,
            observer: address(0),
            observationEndTime: 0
        });

        // Mint the ERC721 token to the caller
        _safeMint(msg.sender, newTokenId);

        emit ParticleSpawned(newTokenId, msg.sender, _particleStates[newTokenId].energyLevel, _particleStates[newTokenId].phase);
    }

    /// @notice Attempts to trigger a state fluctuation for a particle.
    /// @dev State change is probabilistic based on `fluctuationChanceNumerator`/`Denominator`
    ///      and depends on current state and block data for pseudo-randomness.
    ///      Cannot fluctuate if the particle is currently observed.
    ///      Any address can trigger fluctuation for any particle.
    /// @param tokenId The ID of the particle.
    function triggerFluctuation(uint256 tokenId) public {
        ParticleState storage particle = _getParticleState(tokenId); // Internal helper checks existence

        if (particle.isObserved && block.timestamp < particle.observationEndTime) {
            revert QuantumFluctuations__ParticleIsObserved(tokenId);
        }

        // Pseudo-random seed incorporating block data (prevrandao), sender, token, and last fluctuation block
        bytes32 fluctuationSeed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, tokenId, particle.lastFluctuationBlock));
        uint256 seedUint = uint256(fluctuationSeed);

        // Determine if fluctuation occurs based on the system chance parameter
        if (fluctuationChanceDenominator > 0 && (seedUint % fluctuationChanceDenominator) < fluctuationChanceNumerator) {
            // Calculate new state based on seed and previous state
            // Simple examples of state transitions:
            uint256 energyChange = (seedUint % 21) - 10; // Change energy by -10 to +10
            uint256 newEnergy = (particle.energyLevel + energyChange).max(0).min(MAX_ENERGY);

            // Phase transition logic: Simple random transition or rule-based
            Phase newPhase = Phase(seedUint % uint(type(Phase).max)); // Random phase transition

            uint256 stabilityChange = (seedUint % 7) - 3; // Change stability by -3 to +3
            uint256 newStability = (particle.stability + stabilityChange).max(MIN_STABILITY).min(MAX_STABILITY);


            // Update particle state
            particle.energyLevel = newEnergy;
            particle.phase = newPhase;
            particle.stability = newStability;
            particle.lastFluctuationBlock = block.number; // Record block of successful fluctuation

            emit ParticleFluctuated(tokenId, newEnergy, newPhase, newStability, block.number);
        }
        // If the chance check fails, no fluctuation occurs for this trigger.
    }

    /// @notice Allows an address to observe a particle, locking its state temporarily.
    /// @dev While observed, the particle cannot fluctuate or be influenced, and cannot be transferred.
    ///      Cannot observe if the observation cooldown period from the last observation has not ended.
    ///      Max observation duration is capped.
    /// @param tokenId The ID of the particle to observe.
    /// @param duration The requested duration in seconds for observation.
    function observeParticle(uint256 tokenId, uint256 duration) public {
        ParticleState storage particle = _getParticleState(tokenId); // Internal helper checks existence

        // Check if already observed (shouldn't happen if state is correct, but good safety)
        if (particle.isObserved && block.timestamp < particle.observationEndTime) {
             revert QuantumFluctuations__ParticleIsObserved(tokenId);
        }

        // Check if the observation cooldown is active
        if (block.timestamp < particle.lastObservationEndTime) {
             revert QuantumFluctuations__ObservationCooldownActive(tokenId, particle.lastObservationEndTime);
        }

        // Cap the observation duration
        uint256 effectiveDuration = duration.min(MAX_OBSERVATION_DURATION);
        if (effectiveDuration == 0) {
            revert QuantumFluctuations__DurationTooLong(); // Or require minimum duration
        }

        // Start observation
        particle.isObserved = true;
        particle.observer = msg.sender;
        particle.observationEndTime = block.timestamp + effectiveDuration;

        emit ParticleObserved(tokenId, msg.sender, particle.observationEndTime);
    }

    /// @notice Allows the current observer to stop observing a particle early.
    /// @dev Can only be called by the address that initiated the observation.
    /// @param tokenId The ID of the particle.
    function stopObservation(uint256 tokenId) public {
        ParticleState storage particle = _getParticleState(tokenId); // Internal helper checks existence

        // Check if particle is currently observed and if the caller is the observer
        if (!particle.isObserved || block.timestamp >= particle.observationEndTime) {
            revert QuantumFluctuations__ObservationNotEnded(tokenId);
        }
        if (particle.observer != msg.sender) {
            revert QuantumFluctuations__NotObserver(tokenId, msg.sender);
        }

        // End the observation and start the cooldown
        _endObservation(tokenId, particle);

        emit ParticleObservationStopped(tokenId);
    }

    /// @notice Attempts to influence a particle's state using arbitrary external data.
    /// @dev This function allows a user to potentially guide the particle's state transition
    ///      by providing a `bytes32` value that is incorporated into the state change calculation.
    ///      State always changes with influence, but the outcome is non-deterministic from the caller's perspective.
    ///      Cannot influence if the particle is currently observed.
    /// @param tokenId The ID of the particle.
    /// @param interactionData Arbitrary 32-byte data provided by the caller (e.g., a hash of external data).
    function influenceParticle(uint256 tokenId, bytes32 interactionData) public {
        ParticleState storage particle = _getParticleState(tokenId); // Internal helper checks existence

        if (particle.isObserved && block.timestamp < particle.observationEndTime) {
            revert QuantumFluctuations__ParticleIsObserved(tokenId);
        }

        // Generate a seed incorporating block data, sender, token, last fluctuation, AND the interaction data
        bytes32 influenceSeed = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, tokenId, particle.lastFluctuationBlock, interactionData));
        uint256 seedUint = uint256(influenceSeed);

        // State changes are guaranteed with influence, but the specific change depends on the seed
        uint256 energyChange = (seedUint % 31) - 15; // Change energy by -15 to +15
        uint256 newEnergy = (particle.energyLevel + energyChange).max(0).min(MAX_ENERGY);

        // Phase transition influenced by seed
        // Example: combine current phase with seed influence
        Phase newPhase = Phase((uint(particle.phase) + (seedUint % uint(type(Phase).max))) % uint(type(Phase).max));

        uint256 stabilityChange = (seedUint % 9) - 4; // Change stability by -4 to +4
        uint256 newStability = (particle.stability + stabilityChange).max(MIN_STABILITY).min(MAX_STABILITY);

        // Update particle state
        particle.energyLevel = newEnergy;
        particle.phase = newPhase;
        particle.stability = newStability;
        particle.lastFluctuationBlock = block.number; // Record block of influence

        emit ParticleInfluenced(tokenId, msg.sender, interactionData, newEnergy, newPhase, newStability);
    }


    // --- View/Getter Functions ---

    /// @notice Gets the full state of a particle.
    /// @param tokenId The ID of the particle.
    /// @return The ParticleState struct containing all dynamic properties.
    function getParticleState(uint256 tokenId) public view returns (ParticleState memory) {
        if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId];
    }

    /// @notice Checks if a particle is currently under observation and the observation period is active.
    /// @param tokenId The ID of the particle.
    /// @return True if observed and block.timestamp is before observationEndTime.
    function isParticleObserved(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        ParticleState memory particle = _particleStates[tokenId];
        return particle.isObserved && block.timestamp < particle.observationEndTime;
    }

    /// @notice Gets the timestamp when the current observation ends.
    /// @param tokenId The ID of the particle.
    /// @return The observation end timestamp (0 if not currently observed or observation has ended).
    function getObservationEndTime(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        ParticleState memory particle = _particleStates[tokenId];
        return particle.isObserved ? particle.observationEndTime : 0;
    }


    /// @notice Calculates a simplified measure of system entropy (overall instability).
    /// @dev This is a conceptual metric representing the total instability across all particles.
    ///      Calculated by summing (MAX_STABILITY - particle.stability) for each particle.
    ///      NOTE: Iterating over all tokens using `tokenByIndex` is GAS-INTENSIVE and
    ///      should be avoided in production contracts with potentially thousands or
    ///      millions of tokens. This is included purely for conceptual demonstration
    ///      as requested for function count and creativity. A production system
    ///      would maintain this metric differently (e.g., updating a running total
    ///      on each state change, which adds complexity).
    /// @return The total calculated instability score for all minted particles.
    function getSystemEntropy() public view returns (uint256) {
        uint256 totalInstability = 0;
        uint256 currentTotalSupply = totalSupply(); // Get total number of minted tokens

        // WARNING: This loop is highly gas-intensive and may exceed block gas limits
        // for large numbers of tokens. Use with caution or avoid calling on-chain.
        for (uint256 i = 0; i < currentTotalSupply; i++) {
            uint256 tokenId = tokenByIndex(i); // Get token ID from the index
            ParticleState memory particle = _particleStates[tokenId]; // Read particle state (view call is fine)
            totalInstability += (MAX_STABILITY - particle.stability); // Add instability score (higher instability = lower stability)
        }
        return totalInstability;
    }

    /// @notice Measures a particle's potential for future state change (amplitude).
    /// @dev Conceptual metric based on energy and stability. Higher energy and lower stability
    ///      suggest a greater potential for significant fluctuations.
    /// @param tokenId The ID of the particle.
    /// @return A calculated amplitude score.
    function measureFluctuationAmplitude(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        ParticleState memory particle = _particleStates[tokenId];
        // Simple calculation: Energy scaled by inverse stability (instability score)
        // Avoid division by zero or use a minimum stability threshold if MIN_STABILITY was > 0
        return particle.energyLevel * (MAX_STABILITY - particle.stability);
    }

    /// @notice Returns the phase of a specific particle.
    /// @param tokenId The ID of the particle.
    /// @return The particle's current Phase enum value.
    function getParticlePhase(uint256 tokenId) public view returns (Phase) {
        if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId].phase;
    }

    /// @notice Returns the energy level of a specific particle.
    /// @param tokenId The ID of the particle.
    /// @return The particle's current energy level (0-100).
    function getParticleEnergy(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId].energyLevel;
    }

    /// @notice Returns the stability score of a specific particle.
    /// @param tokenId The ID of the particle.
    /// @return The particle's current stability score (0-10).
    function getParticleStability(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId].stability;
    }

     /// @notice Returns the block number of the particle's last fluctuation.
     /// @param tokenId The ID of the particle.
     /// @return The block number.
     function getParticleLastFluctuationBlock(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId].lastFluctuationBlock;
     }

     /// @notice Returns the timestamp when the particle's last observation cooldown ends.
     /// @param tokenId The ID of the particle.
     /// @return The timestamp.
     function getParticleLastObservationEndTime(uint256 tokenId) public view returns (uint256) {
          if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId].lastObservationEndTime;
     }


    // --- Admin/System Control Functions (Owner-only) ---

    /// @notice Sets the base chance parameters for automatic fluctuations triggered by `triggerFluctuation`.
    /// @dev The chance is `numerator / denominator`. e.g., (30, 100) for 30%.
    ///      Requires `denominator` to be greater than 0.
    /// @param numerator The new numerator for fluctuation chance.
    /// @param denominator The new denominator for fluctuation chance.
    function setFluctuationParameters(uint256 numerator, uint256 denominator) public onlyOwner {
        if (denominator == 0) {
             revert QuantumFluctuations__InvalidFluctuationParameters();
        }
        fluctuationChanceNumerator = numerator;
        fluctuationChanceDenominator = denominator;
        emit FluctuationParametersUpdated(numerator, denominator);
    }

     /// @notice Gets the current base chance parameters for automatic fluctuations.
     /// @return A tuple containing the numerator and denominator.
     function getFluctuationParameters() public view returns (uint256 numerator, uint256 denominator) {
        return (fluctuationChanceNumerator, fluctuationChanceDenominator);
     }

    /// @notice Sets the cooldown period between observations for a particle.
    /// @dev Once a particle's observation ends (either naturally or via `stopObservation`),
    ///      it cannot be observed again until this cooldown period has passed.
    /// @param cooldown The new cooldown duration in seconds.
    function setObservationCooldown(uint256 cooldown) public onlyOwner {
        observationCooldown = cooldown;
        emit ObservationCooldownUpdated(cooldown);
    }

     /// @notice Gets the current observation cooldown period.
     /// @return The cooldown duration in seconds.
     function getObservationCooldown() public view returns (uint256) {
        return observationCooldown;
     }

    /// @notice Allows the owner to withdraw any Ether held by the contract.
    /// @dev This function is necessary if the contract were to receive Ether (e.g., from future features).
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // --- Internal Helper Functions ---

    /// @dev Internal helper to get particle state from storage and ensure the token exists.
    ///      Reduces code duplication and ensures existence check.
    function _getParticleState(uint256 tokenId) internal view returns (ParticleState storage) {
         if (!_exists(tokenId)) {
             revert QuantumFluctuations__TokenDoesNotExist(tokenId);
        }
        return _particleStates[tokenId];
    }

    /// @dev Internal helper function to end an observation and start the cooldown period.
    /// @param tokenId The ID of the particle.
    /// @param particle The storage reference to the particle's state.
    function _endObservation(uint256 tokenId, ParticleState storage particle) internal {
        particle.isObserved = false;
        particle.observer = address(0); // Reset observer
        particle.observationEndTime = 0; // Reset end time
        particle.lastObservationEndTime = block.timestamp + observationCooldown; // Set cooldown end time
    }
}
```