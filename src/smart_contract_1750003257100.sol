Okay, here is a Solidity smart contract implementing a concept I'll call "Quantum Entangled NFTs". This concept explores state-changing NFTs where attributes of paired tokens are linked and can influence each other, introducing mechanics like interaction-triggered state shifts, external "fluctuations", and a process of "decoherence".

This is an advanced concept involving complex state management and interaction patterns that go beyond standard ERC-721 functionalities.

---

### Smart Contract Outline & Function Summary

**Contract Name:** `QuantumEntangledNFTs`

**Concept:** Implements a unique type of non-fungible token where NFTs are created in pairs ("entangled twins"). The state and attributes of one NFT in a pair can instantaneously influence the state and attributes of its entangled twin, regardless of ownership. Includes mechanics for interaction, external "fluctuations", and a "decoherence" process that can eventually break the entanglement.

**Inherits:** ERC721, Ownable (from OpenZeppelin)

**Key Data Structures:**

*   `NFTState`: Struct holding dynamic attributes (e.g., `energy`, `stability`, `frequency`), interaction timestamps, and metadata lock status.

**Core Mechanics:**

1.  **Entangled Minting:** NFTs are always minted in pairs.
2.  **State Entanglement:** State-changing functions called on one NFT (`interactWithTwin`, `applyFluctuation`) can affect *both* NFTs in the entangled pair.
3.  **Dynamic Attributes:** Attributes (`energy`, `stability`, `frequency`) change based on interactions, fluctuations, and the state of the twin.
4.  **Resonance/Interference:** A function (`attemptResonance`) allows comparing twin states to potentially apply positive ("resonance") or negative ("interference") effects.
5.  **Decoherence:** A multi-step process (`initiateDecoherence`, `breakEntanglement`) allows for the potential breaking of the entanglement link after a certain period or conditions.
6.  **Metadata Locking:** Owners can lock the dynamic state attributes reflected in the metadata URI.
7.  **Dynamic Metadata:** The `tokenURI` function provides a pointer; the *content* of the metadata JSON is expected to be dynamically generated off-chain based on the current on-chain state retrieved via `getTokenAttributes`.

**Function Summary (approx. 24 custom functions + ERC721/Ownable):**

*   **Core ERC721 (Overridden/Used):**
    *   `constructor(string name, string symbol)`: Initializes contract.
    *   `tokenURI(uint256 tokenId)`: Returns the URI for the token's metadata (dynamically reflects state).
    *   `transferFrom(address from, address to, uint256 tokenId)`: Standard transfer, entanglement persists.
    *   `safeTransferFrom(...)`: Standard safe transfer, entanglement persists.
    *   (And others like `balanceOf`, `ownerOf`, `approve`, etc. from inherited contracts).
*   **Minting:**
    *   `mintEntangledPair(address owner)`: Mints a new entangled pair of NFTs, assigning both to the specified owner.
*   **Queries (View/Pure):**
    *   `getEntangledTwin(uint256 tokenId)`: Returns the token ID of the entangled twin.
    *   `getTokenState(uint256 tokenId)`: Returns the full `NFTState` struct for a token.
    *   `getTokenAttributes(uint256 tokenId)`: Returns specific dynamic attributes for metadata services.
    *   `isPairEntangled(uint256 tokenId)`: Checks if the token's pair is currently entangled.
    *   `getPairId(uint256 tokenId)`: Returns the unique identifier for the pair.
    *   `getDecoherenceStartTime(uint256 tokenId)`: Gets the block timestamp when decoherence was initiated for the pair.
    *   `getDecoherenceDuration()`: Gets the required duration for decoherence.
    *   `isDecoherencePeriodMet(uint256 tokenId)`: Checks if the required decoherence duration has passed.
    *   `getBaseURI()`: Gets the base URI for metadata.
    *   `getFluctuationMagnitude()`: Gets the current fluctuation magnitude parameter.
    *   `getResonanceThreshold()`: Gets the current resonance threshold parameter.
    *   `getInterferenceThreshold()`: Gets the current interference threshold parameter.
*   **State Interaction & Manipulation:**
    *   `interactWithTwin(uint256 tokenId)`: Triggers a state change interaction between a token and its twin.
    *   `applyFluctuation(uint256 tokenId)`: Applies a pseudo-random state fluctuation to the token and its twin.
    *   `attemptResonance(uint256 tokenId)`: Attempts to trigger resonance or interference effects based on twin states.
*   **Decoherence:**
    *   `initiateDecoherence(uint256 tokenId)`: Starts the decoherence process for the entangled pair.
    *   `breakEntanglement(uint256 tokenId)`: Finalizes decoherence and breaks the entanglement link (requires time duration to pass).
*   **Metadata Control:**
    *   `lockMetadata(uint256 tokenId)`: Locks the dynamic attributes reflected in the metadata for a token.
    *   `unlockMetadata(uint256 tokenId)`: Unlocks the dynamic attributes.
    *   `isMetadataLocked(uint256 tokenId)`: Checks if metadata is locked.
*   **Owner-Only Configuration:**
    *   `setBaseURI(string baseURI)`: Sets the base URI for token metadata.
    *   `setDecoherenceDuration(uint64 duration)`: Sets the time required for decoherence.
    *   `setFluctuationMagnitude(uint256 magnitude)`: Sets the maximum impact of fluctuations.
    *   `setResonanceThreshold(uint256 threshold)`: Sets the threshold for resonance.
    *   `setInterferenceThreshold(uint256 threshold)`: Sets the threshold for interference.
    *   `setInitialNFTState(uint256 energy, uint256 stability, uint256 frequency)`: Sets the initial state values for new NFTs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Smart Contract Outline & Function Summary ---
//
// Contract Name: QuantumEntangledNFTs
// Concept: ERC721 tokens minted in entangled pairs. State changes on one can affect its twin.
// Mechanics: Entangled minting, state entanglement, dynamic attributes, resonance/interference, decoherence process, metadata locking.
// Inherits: ERC721, ERC721Enumerable, Ownable
// Key Data Structures: NFTState struct (energy, stability, frequency, interaction time, metadata lock).
// Functions: Includes core ERC721 overrides, pair minting, state queries, state interaction (interactWithTwin, applyFluctuation), resonance logic (attemptResonance), decoherence initiation & breaking, metadata locking/unlocking, owner configuration of parameters. (Approx 24 custom functions + inherited).
//
// See detailed function summary above the code block for specifics.
//
// ---

contract QuantumEntangledNFTs is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _pairIdCounter;

    // --- State Variables ---

    // Maps tokenId to its entangled twin tokenId
    mapping(uint256 tokenId => uint256 twinTokenId) public entangledPair;

    // Struct defining the dynamic state of an NFT
    struct NFTState {
        uint256 energy;     // Represents vitality, potentially used for utility
        uint256 stability;  // Represents resilience, resists negative fluctuations
        uint256 frequency;  // Represents unique 'signature', influences resonance
        uint64 lastInteractionTime; // Block timestamp of the last interaction
        bool metadataLocked; // If true, state changes don't affect metadata URI content (conceptually)
    }

    // Maps tokenId to its current state
    mapping(uint256 tokenId => NFTState) public tokenStates;

    // Maps pairId (min of the two tokenIds) to whether the pair is still entangled
    mapping(uint256 pairId => bool) public isEntangled;

    // Maps pairId to the timestamp when decoherence was initiated
    mapping(uint256 pairId => uint64) public decoherenceStartTime;

    // Base URI for token metadata
    string private _baseURI;

    // Configuration parameters (owner controllable)
    uint64 public decoherenceDuration = 7 days; // Time required for decoherence after initiation
    uint256 public fluctuationMagnitude = 10; // Max amount state attributes can change from fluctuation
    uint256 public resonanceThreshold = 5; // Difference threshold for frequency to trigger resonance/interference
    uint256 public resonanceBoost = 15; // Boost to energy/stability on resonance
    uint256 public interferencePenalty = 10; // Penalty to energy/stability on interference

    // Initial state values for new NFTs
    uint256 public initialEnergy = 50;
    uint256 public initialStability = 50;
    uint256 public initialFrequency = 100;

    // --- Events ---

    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 pairId);
    event DecoherenceInitiated(uint256 indexed pairId, uint64 startTime);
    event DecoherenceBroken(uint256 indexed pairId, uint256 tokenId1, uint256 tokenId2);
    event StateChanged(uint256 indexed tokenId, NFTState newState);
    event MetadataLocked(uint256 indexed tokenId);
    event MetadataUnlocked(uint256 indexed tokenId);
    event ResonanceApplied(uint256 indexed pairId, uint256 tokenId1, uint256 tokenId2, uint256 energyChange, uint256 stabilityChange);
    event InterferenceApplied(uint256 indexed pairId, uint256 tokenId1, uint256 tokenId2, uint256 energyChange, uint256 stabilityChange);

    // --- Modifiers ---

    modifier onlyEntangledPair(uint256 tokenId) {
        uint256 pairId = getPairId(tokenId);
        require(isEntangled[pairId], "QENFT: Pair is not entangled");
        _;
    }

    modifier onlyIfNotMetadataLocked(uint256 tokenId) {
        require(!tokenStates[tokenId].metadataLocked, "QENFT: Metadata is locked");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Core ERC721 Overrides ---

    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Conceptual dynamic metadata: The metadata server would use getTokenAttributes
        // to generate the actual JSON based on the current state.
        // This function just provides the pointer.
        return bytes(_baseURI).length > 0
            ? string(abi.encodePacked(_baseURI, Strings.toString(tokenId), ".json"))
            : "";
    }

    // Override required to use ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Overrides needed for ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    // Transfer does NOT break entanglement by default
    function transferFrom(address from, address to, uint256 tokenId) public override onlyEntangledPair(tokenId) {
        super.transferFrom(from, to, tokenId);
        // Entanglement persists across ownership changes
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyEntangledPair(tokenId) {
         super.safeTransferFrom(from, to, tokenId);
         // Entanglement persists across ownership changes
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyEntangledPair(tokenId) {
         super.safeTransferFrom(from, to, tokenId, data);
         // Entanglement persists across ownership changes
    }


    // --- Custom Functions ---

    // --- Minting ---

    /// @notice Mints a new pair of entangled NFTs to the specified owner.
    /// @param owner The address to mint the entangled pair to.
    function mintEntangledPair(address owner) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId1 = _tokenIdCounter.current();
        _safeMint(owner, tokenId1);

        _tokenIdCounter.increment();
        uint256 tokenId2 = _tokenIdCounter.current();
        _safeMint(owner, tokenId2);

        uint256 currentPairId = Math.min(tokenId1, tokenId2);
        _pairIdCounter.increment(); // Use a separate counter for pair IDs if needed for enumeration, or just use min(id1, id2)

        entangledPair[tokenId1] = tokenId2;
        entangledPair[tokenId2] = tokenId1;

        isEntangled[currentPairId] = true;

        // Initialize state for both tokens
        tokenStates[tokenId1] = NFTState({
            energy: initialEnergy,
            stability: initialStability,
            frequency: initialFrequency,
            lastInteractionTime: uint64(block.timestamp),
            metadataLocked: false
        });
         tokenStates[tokenId2] = NFTState({
            energy: initialEnergy,
            stability: initialStability,
            frequency: initialFrequency,
            lastInteractionTime: uint64(block.timestamp),
            metadataLocked: false
        });

        emit Entangled(tokenId1, tokenId2, currentPairId);
        emit StateChanged(tokenId1, tokenStates[tokenId1]);
        emit StateChanged(tokenId2, tokenStates[tokenId2]);
    }

    // --- Queries (View/Pure) ---

    /// @notice Gets the token ID of the entangled twin for a given token ID.
    /// @param tokenId The ID of the token.
    /// @return The ID of the entangled twin, or 0 if not part of a pair.
    function getEntangledTwin(uint256 tokenId) public view returns (uint256) {
        return entangledPair[tokenId];
    }

    /// @notice Gets the current dynamic state attributes of a token.
    /// @param tokenId The ID of the token.
    /// @return The NFTState struct.
    function getTokenState(uint256 tokenId) public view returns (NFTState memory) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return tokenStates[tokenId];
    }

     /// @notice Gets the dynamic attributes relevant for metadata generation.
     /// @param tokenId The ID of the token.
     /// @return energy, stability, frequency, metadataLocked status.
     function getTokenAttributes(uint256 tokenId) public view returns (uint256 energy, uint256 stability, uint256 frequency, bool metadataLocked) {
         require(_exists(tokenId), "QENFT: Token does not exist");
         NFTState memory state = tokenStates[tokenId];
         return (state.energy, state.stability, state.frequency, state.metadataLocked);
     }

    /// @notice Checks if the pair associated with a token ID is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isPairEntangled(uint256 tokenId) public view returns (bool) {
        uint256 twinId = entangledPair[tokenId];
        if (twinId == 0) return false; // Not even part of a pair
        uint256 pairId = getPairId(tokenId);
        return isEntangled[pairId];
    }

    /// @notice Gets the unique identifier for the pair associated with a token ID.
    /// @param tokenId The ID of the token.
    /// @return The pair ID (min of the two token IDs). Returns 0 if not part of a pair.
    function getPairId(uint256 tokenId) public view returns (uint256) {
        uint256 twinId = entangledPair[tokenId];
        if (twinId == 0) return 0;
        return Math.min(tokenId, twinId);
    }

    /// @notice Gets the block timestamp when decoherence was initiated for a pair.
    /// @param tokenId The ID of a token in the pair.
    /// @return The timestamp, or 0 if decoherence hasn't been initiated.
    function getDecoherenceStartTime(uint256 tokenId) public view returns (uint64) {
        uint256 pairId = getPairId(tokenId);
        if (pairId == 0) return 0;
        return decoherenceStartTime[pairId];
    }

    /// @notice Gets the required duration for decoherence to complete after initiation.
    /// @return The duration in seconds.
    function getDecoherenceDuration() public view returns (uint64) {
        return decoherenceDuration;
    }

     /// @notice Checks if the required decoherence duration has passed since initiation.
     /// @param tokenId The ID of a token in the pair.
     /// @return True if duration met, false otherwise.
     function isDecoherencePeriodMet(uint256 tokenId) public view returns (bool) {
         uint256 pairId = getPairId(tokenId);
         if (pairId == 0 || decoherenceStartTime[pairId] == 0) return false; // Not a valid pair or decoherence not started
         return block.timestamp >= decoherenceStartTime[pairId] + decoherenceDuration;
     }

    /// @notice Gets the current base URI for token metadata.
    /// @return The base URI string.
    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    /// @notice Gets the current fluctuation magnitude parameter.
    /// @return The magnitude value.
    function getFluctuationMagnitude() public view returns (uint256) {
        return fluctuationMagnitude;
    }

    /// @notice Gets the current resonance threshold parameter.
    /// @return The threshold value.
    function getResonanceThreshold() public view returns (uint256) {
        return resonanceThreshold;
    }

     /// @notice Gets the current interference threshold parameter.
     /// @return The threshold value.
     function getInterferenceThreshold() public view returns (uint256) {
         return interferenceThreshold;
     }

    // --- State Interaction & Manipulation ---

    /// @notice Triggers an interaction effect between a token and its entangled twin.
    /// @dev This function causes state changes in both NFTs based on their current states.
    /// @param tokenId The ID of the token initiating the interaction.
    function interactWithTwin(uint256 tokenId) public onlyEntangledPair(tokenId) onlyIfNotMetadataLocked(tokenId) onlyIfNotMetadataLocked(entangledPair[tokenId]) {
        uint256 twinId = entangledPair[tokenId];
        NFTState storage state1 = tokenStates[tokenId];
        NFTState storage state2 = tokenStates[twinId];

        // Apply interaction logic (example):
        // Interaction drains energy slightly, boosts frequency
        state1.energy = state1.energy >= 1 ? state1.energy - 1 : 0;
        state1.frequency += 2; // Frequency increases with interaction

        // Twin's state is affected by the initiator's state (example):
        // Twin's stability might increase if initiator's frequency is high
        if (state1.frequency > 150) {
            state2.stability += 1;
        } else {
             state2.stability = state2.stability >= 1 ? state2.stability - 1 : 0;
        }
        state2.energy = state2.energy >= 1 ? state2.energy - 1 : 0; // Both consume energy through interaction

        state1.lastInteractionTime = uint64(block.timestamp);
        state2.lastInteractionTime = uint64(block.timestamp); // Both update time

        emit StateChanged(tokenId, state1);
        emit StateChanged(twinId, state2);
    }

    /// @notice Applies a "quantum fluctuation" effect to the token and its entangled twin.
    /// @dev Uses block data as a pseudo-random seed (note: EVM randomness is weak).
    /// @param tokenId The ID of a token in the pair.
    function applyFluctuation(uint256 tokenId) public onlyEntangledPair(tokenId) onlyIfNotMetadataLocked(tokenId) onlyIfNotMetadataLocked(entangledPair[tokenId]) {
        uint256 twinId = entangledPair[tokenId];
        NFTState storage state1 = tokenStates[tokenId];
        NFTState storage state2 = tokenStates[twinId];

        // Using block data for a pseudo-random seed (weak randomness, for demonstration)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tokenId)));

        int256 fluctuation1_energy = int256((seed % (2 * fluctuationMagnitude + 1)) - fluctuationMagnitude); // Range [-mag, mag]
        int256 fluctuation1_stability = int256(((seed / 10) % (2 * fluctuationMagnitude + 1)) - fluctuationMagnitude);
        int256 fluctuation2_energy = int256(((seed / 20) % (2 * fluctuationMagnitude + 1)) - fluctuationMagnitude);
        int256 fluctuation2_stability = int256(((seed / 30) % (2 * fluctuationMagnitude + 1)) - fluctuationMagnitude);

        // Apply fluctuations, ensuring no negative results for unsigned ints
        state1.energy = fluctuation1_energy >= 0 ? state1.energy + uint256(fluctuation1_energy) : (state1.energy >= uint256(-fluctuation1_energy) ? state1.energy - uint256(-fluctuation1_energy) : 0);
        state1.stability = fluctuation1_stability >= 0 ? state1.stability + uint256(fluctuation1_stability) : (state1.stability >= uint256(-fluctuation1_stability) ? state1.stability - uint256(-fluctuation1_stability) : 0);
        state2.energy = fluctuation2_energy >= 0 ? state2.energy + uint256(fluctuation2_energy) : (state2.energy >= uint256(-fluctuation2_energy) ? state2.energy - uint256(-fluctuation2_energy) : 0);
        state2.stability = fluctuation2_stability >= 0 ? state2.stability + uint256(fluctuation2_stability) : (state2.stability >= uint256(-fluctuation2_stability) ? state2.stability - uint256(-fluctuation2_stability) : 0);

        // Ensure attributes don't exceed reasonable bounds (optional, adjust as needed)
        state1.energy = Math.min(state1.energy, 200);
        state1.stability = Math.min(state1.stability, 200);
        state2.energy = Math.min(state2.energy, 200);
        state2.stability = Math.min(state2.stability, 200);


        emit StateChanged(tokenId, state1);
        emit StateChanged(twinId, state2);
    }

     /// @notice Attempts to trigger resonance or interference between entangled twins based on their frequency difference.
     /// @dev If frequencies are close, resonance applies a positive boost. If far, interference applies a penalty.
     /// @param tokenId The ID of a token in the pair.
     function attemptResonance(uint256 tokenId) public onlyEntangledPair(tokenId) onlyIfNotMetadataLocked(tokenId) onlyIfNotMetadataLocked(entangledPair[tokenId]) {
        uint256 twinId = entangledPair[tokenId];
        NFTState storage state1 = tokenStates[tokenId];
        NFTState storage state2 = tokenStates[twinId];

        uint256 freqDiff = state1.frequency > state2.frequency ? state1.frequency - state2.frequency : state2.frequency - state1.frequency;

        if (freqDiff <= resonanceThreshold) {
            // Resonance: boost energy and stability for both
            state1.energy += resonanceBoost;
            state1.stability += resonanceBoost;
            state2.energy += resonanceBoost;
            state2.stability += resonanceBoost;
             emit ResonanceApplied(getPairId(tokenId), tokenId, twinId, resonanceBoost, resonanceBoost);
        } else if (freqDiff >= interferenceThreshold) {
            // Interference: penalize energy and stability for both
            state1.energy = state1.energy >= interferencePenalty ? state1.energy - interferencePenalty : 0;
            state1.stability = state1.stability >= interferencePenalty ? state1.stability - interferencePenalty : 0;
            state2.energy = state2.energy >= interferencePenalty ? state2.energy - interferencePenalty : 0;
            state2.stability = state2.stability >= interferencePenalty ? state2.stability - interferencePenalty : 0;
            emit InterferenceApplied(getPairId(tokenId), tokenId, twinId, interferencePenalty, interferencePenalty);
        }
        // Else: Frequencies are moderately different, no special effect.

        // Ensure attributes don't exceed reasonable bounds (optional)
        state1.energy = Math.min(state1.energy, 200);
        state1.stability = Math.min(state1.stability, 200);
        state2.energy = Math.min(state2.energy, 200);
        state2.stability = Math.min(state2.stability, 200);


        emit StateChanged(tokenId, state1);
        emit StateChanged(twinId, state2);
    }


    // --- Decoherence ---

    /// @notice Initiates the decoherence process for an entangled pair.
    /// @dev This sets a timestamp. Entanglement cannot be broken until decoherenceDuration has passed.
    /// @param tokenId The ID of a token in the pair.
    function initiateDecoherence(uint256 tokenId) public onlyEntangledPair(tokenId) {
        uint256 pairId = getPairId(tokenId);
        require(decoherenceStartTime[pairId] == 0, "QENFT: Decoherence already initiated");

        decoherenceStartTime[pairId] = uint64(block.timestamp);
        emit DecoherenceInitiated(pairId, decoherenceStartTime[pairId]);
    }

    /// @notice Breaks the entanglement link for a pair after the decoherence period has passed.
    /// @dev This finalizes the state and removes the entangled link.
    /// @param tokenId The ID of a token in the pair.
    function breakEntanglement(uint256 tokenId) public onlyEntangledPair(tokenId) {
        uint256 pairId = getPairId(tokenId);
        uint256 twinId = entangledPair[tokenId];

        require(decoherenceStartTime[pairId] > 0, "QENFT: Decoherence not initiated");
        require(isDecoherencePeriodMet(tokenId), "QENFT: Decoherence period not yet met");

        // Optional: Finalize state upon breaking entanglement
        // tokenStates[tokenId].energy = Math.min(tokenStates[tokenId].energy + 20, 255); // Example final boost
        // tokenStates[twinId].stability = Math.min(tokenStates[twinId].stability + 20, 255);

        // Remove entanglement mapping
        delete entangledPair[tokenId];
        delete entangledPair[twinId];

        // Mark pair as not entangled
        isEntangled[pairId] = false;
        // Keep decoherenceStartTime for historical reference or clean up if preferred

        emit DecoherenceBroken(pairId, tokenId, twinId);
        // Could emit final StateChanged events here if states were finalized
    }


    // --- Metadata Control ---

    /// @notice Locks the dynamic state attributes for a token.
    /// @dev When locked, state-changing functions will revert if called on this token or its twin.
    /// @param tokenId The ID of the token to lock metadata for.
    function lockMetadata(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QENFT: Not token owner");
        tokenStates[tokenId].metadataLocked = true;
        emit MetadataLocked(tokenId);
    }

    /// @notice Unlocks the dynamic state attributes for a token.
    /// @dev Allows state-changing functions to affect this token's attributes again.
    /// @param tokenId The ID of the token to unlock metadata for.
    function unlockMetadata(uint256 tokenId) public {
         require(_exists(tokenId), "QENFT: Token does not exist");
         require(ownerOf(tokenId) == msg.sender, "QENFT: Not token owner");
         tokenStates[tokenId].metadataLocked = false;
         emit MetadataUnlocked(tokenId);
    }

     /// @notice Checks if the metadata for a token is locked.
     /// @param tokenId The ID of the token.
     /// @return True if metadata is locked, false otherwise.
     function isMetadataLocked(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "QENFT: Token does not exist");
         return tokenStates[tokenId].metadataLocked;
     }


    // --- Owner-Only Configuration ---

    /// @notice Sets the base URI for token metadata.
    /// @param baseURI The new base URI string.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURI = baseURI;
    }

    /// @notice Sets the duration required for decoherence to complete after initiation.
    /// @param duration The duration in seconds.
    function setDecoherenceDuration(uint64 duration) public onlyOwner {
        decoherenceDuration = duration;
    }

    /// @notice Sets the maximum impact of fluctuations on state attributes.
    /// @param magnitude The new fluctuation magnitude.
    function setFluctuationMagnitude(uint256 magnitude) public onlyOwner {
        fluctuationMagnitude = magnitude;
    }

    /// @notice Sets the frequency difference threshold for triggering resonance.
    /// @param threshold The new resonance threshold.
    function setResonanceThreshold(uint256 threshold) public onlyOwner {
        resonanceThreshold = threshold;
    }

     /// @notice Sets the frequency difference threshold for triggering interference.
     /// @param threshold The new interference threshold.
     function setInterferenceThreshold(uint256 threshold) public onlyOwner {
         interferenceThreshold = threshold;
     }

     /// @notice Sets the initial state values for newly minted NFTs.
     /// @param energy Initial energy value.
     /// @param stability Initial stability value.
     /// @param frequency Initial frequency value.
     function setInitialNFTState(uint256 energy, uint256 stability, uint256 frequency) public onlyOwner {
         initialEnergy = energy;
         initialStability = stability;
         initialFrequency = frequency;
     }

    // --- Internal/Helper Functions (Used by overrides or other public functions) ---

    // ERC721Enumerable requires these overrides
    // These are included as part of the contract's function count but are standard overrides.

    // Function 23 (inherited from ERC721)
    // Function 24 (inherited from ERC721Enumerable)
    // ... and many more inherited functions like balanceOf, ownerOf, etc.
    // The *custom* functions are the ones listed above.

}
```