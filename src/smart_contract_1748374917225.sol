Okay, this is a fun challenge! We need a complex, non-standard smart contract with at least 20 functions, incorporating advanced, creative, and trendy concepts.

Let's create a contract based on the idea of **Quantum-Inspired Dynamic NFTs with Entanglement and Decay**.

**Concept:** Each NFT represents a "Quantum Key". It has a state that can be in "superposition" (multiple potential values) until "measured" (fixed to one value for a time). Keys can be "entangled" with others, linking their fates. Keys also "decay" over time, reducing their effectiveness unless "re-energized" or "re-measured". The key's state determines its "access level" or utility within a hypothetical system.

**Advanced/Creative/Trendy Elements:**
1.  **Dynamic State:** NFT properties (`currentState`, `accessLevel`) change based on actions (`measureSuperposition`) and time (`applyDecoherence`).
2.  **Superposition/Measurement Simulation:** A state transition triggered by a transaction with cooldowns.
3.  **Entanglement Simulation:** Linking two NFTs such that actions on one can affect the other.
4.  **Time-Based Decay:** Utility decreases over time, requiring interaction to maintain.
5.  **Parameterized Properties:** Decoherence rate, measurement cooldown, etc., are contract parameters.
6.  **Role-Based Access (Implicit):** Owner/Operator pattern from ERC721 + custom access logic based on key state.
7.  **Complex Utility:** The `accessLevel` derived from multiple factors (measured state, decay, entanglement).
8.  **Pseudorandomness:** Incorporating block data/entropy for state generation (acknowledging blockchain limitations vs. true randomness).
9.  **Pausable:** Standard but good practice.
10. **Enumerable:** Provides extra utility and function count.

**Outline:**

1.  **Contract Setup:** SPDX License, Pragma, Imports (ERC721, Ownable, Pausable, Enumerable).
2.  **Errors & Events:** Custom errors and relevant events for state changes.
3.  **State Variables:** Owner, Paused status, token counter, mappings for key data, parameters (cooldown, rates), fees.
4.  **Structs:** `KeyData` struct to hold all properties for each NFT.
5.  **Constructor:** Initialize base ERC721, owner, and initial parameters.
6.  **Modifiers:** Custom modifier for owner/approved check.
7.  **ERC721 Core Functions:** Standard implementations (`balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc.).
8.  **ERC721 Enumerable Functions:** (`totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`).
9.  **ERC165 Support:** `supportsInterface`.
10. **Core Quantum Logic Functions:**
    *   `mintKey`: Create a new Quantum Key NFT with initial superposition.
    *   `measureSuperposition`: Trigger the observation, fixing the state.
    *   `applyDecoherence`: Explicitly apply decay based on time (can be called by anyone to update state).
    *   `entangleKeys`: Link two keys.
    *   `disentangleKeys`: Unlink two keys.
    *   `observeEntangledState`: Measure an entangled key, potentially influencing its pair.
11. **Utility & State Query Functions:**
    *   `getKeyDetails`: Retrieve all data for a key.
    *   `getAccessLevel`: Calculate the *current* effective access level.
    *   `calculatePotentialAccessLevel`: Calculate access based on a *hypothetical* measured state and current decay.
    *   `getCurrentDecayFactor`: Get the current decay multiplier for a key.
    *   `getTimeSinceLastObservation`: Check cooldown status.
    *   `isEntangled`: Check if a key is entangled.
    *   `getEntangledPair`: Get the ID of the entangled key.
12. **Admin & Management Functions:**
    *   `pauseContract`, `unpauseContract`: Control contract activity.
    *   `setMeasurementCooldown`: Update parameter.
    *   `setDecoherenceRate`: Update parameter.
    *   `setEntanglementFee`: Update parameter.
    *   `withdrawFees`: Owner withdraws collected entanglement fees.
    *   `updateTokenURI`: Allow owner to update metadata endpoint.
13. **Internal Helper Functions:**
    *   `_generateSuperposition`: Logic for creating the initial state.
    *   `_calculateDecayFactor`: Logic for decay calculation.
    *   `_applyEntanglementEffect`: Logic for how entanglement influences state/measurement.
    *   `_updateKeyAccessLevel`: Internal function to re-calculate and update access level.

**Function Summary (Count: ~34 functions, >20 satisfied):**

*   `constructor()`: Initializes contract parameters and base contracts.
*   `pause()`: Pauses transfers and specific state-changing functions (Owner).
*   `unpause()`: Unpauses the contract (Owner).
*   `mintKey()`: Mints a new QuantumKey NFT with a generated superposition state. (External)
*   `measureSuperposition(uint256 tokenId)`: "Measures" a key's superposition, setting its current state based on internal logic and applying cooldown. (External)
*   `applyDecoherence(uint256 tokenId)`: Applies time-based decay to a key's effective state and recalculates its access level. Can be called by anyone to refresh state. (External)
*   `entangleKeys(uint256 tokenId1, uint256 tokenId2)`: Links two unentangled keys, requiring ownership/approval and paying a fee. (External, Payable)
*   `disentangleKeys(uint256 tokenId)`: Breaks the entanglement link for a key. (External)
*   `observeEntangledState(uint256 tokenId)`: Measures an entangled key, potentially triggering a linked effect or state change on its entangled pair. (External)
*   `getAccessLevel(uint256 tokenId)`: Returns the current calculated effective access level of a key, considering state and decay. (View)
*   `getKeyDetails(uint256 tokenId)`: Returns the comprehensive state data (struct) for a given key. (View)
*   `calculatePotentialAccessLevel(uint256 tokenId, uint256 assumedMeasuredState)`: Calculates what the access level *would be* if the key was measured into a specific state, considering current decay. (View)
*   `getCurrentDecayFactor(uint256 tokenId)`: Returns the current decay multiplier based on last observation time and decoherence rate. (View)
*   `getTimeSinceLastObservation(uint256 tokenId)`: Returns the time elapsed since the key was last measured. (View)
*   `isEntangled(uint256 tokenId)`: Checks if a key is currently entangled. (View)
*   `getEntangledPair(uint256 tokenId)`: Returns the token ID of the key's entangled partner, or 0 if not entangled. (View)
*   `setMeasurementCooldown(uint256 cooldownSeconds)`: Sets the duration before a key can be measured again (Owner). (External)
*   `setDecoherenceRate(uint256 rate)`: Sets the global rate of state decay over time (Owner). (External)
*   `setEntanglementFee(uint256 fee)`: Sets the fee required to entangle two keys (Owner). (External)
*   `withdrawFees()`: Allows the owner to withdraw collected entanglement fees (Owner). (External)
*   `updateTokenURI(string memory baseURI)`: Sets the base URI for dynamic metadata (Owner). (External)
*   `balanceOf(address owner)`: ERC721 standard. (View)
*   `ownerOf(uint256 tokenId)`: ERC721 standard. (View)
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard. (External)
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard. (External)
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard. (External)
*   `approve(address to, uint256 tokenId)`: ERC721 standard. (External)
*   `setApprovalForAll(address operator, bool approved)`: ERC721 standard. (External)
*   `getApproved(uint256 tokenId)`: ERC721 standard. (View)
*   `isApprovedForAll(address owner, address operator)`: ERC721 standard. (View)
*   `setTokenURI(uint256 tokenId, string memory uri)`: *Correction:* ERC721 standard `tokenURI(uint256 tokenId)` returns the URI. A setter might be needed if URI isn't purely base + ID. Let's rely on a dynamic base URI and off-chain metadata service for the complex state reflection. So, `tokenURI(uint256 tokenId)` is the function name. (View)
*   `supportsInterface(bytes4 interfaceId)`: ERC165 standard. (View)
*   `name()`: ERC721 standard. (View)
*   `symbol()`: ERC721 standard. (View)
*   `totalSupply()`: ERC721 Enumerable standard. (View)
*   `tokenByIndex(uint256 index)`: ERC721 Enumerable standard. (View)
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: ERC721 Enumerable standard. (View)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For max

/**
 * @title QuantumKeyNFT
 * @dev A dynamic NFT simulating quantum concepts like superposition, measurement, entanglement, and decay.
 * The state of the NFT changes over time and via interactions, influencing its utility (access level).
 *
 * Outline:
 * 1. Contract Setup: SPDX, Pragma, Imports (ERC721, Ownable, Pausable, Enumerable)
 * 2. Errors & Events: Custom errors and relevant events
 * 3. State Variables: Owner, Paused, token counter, mappings for key data, parameters, fees
 * 4. Structs: KeyData struct
 * 5. Constructor: Initialization
 * 6. Modifiers: onlyKeyOwnerOrApproved
 * 7. ERC721 Core Functions: Standard implementations
 * 8. ERC721 Enumerable Functions: Standard implementations
 * 9. ERC165 Support: supportsInterface
 * 10. Core Quantum Logic Functions: mintKey, measureSuperposition, applyDecoherence, entangleKeys, disentangleKeys, observeEntangledState
 * 11. Utility & State Query Functions: getKeyDetails, getAccessLevel, calculatePotentialAccessLevel, getCurrentDecayFactor, getTimeSinceLastObservation, isEntangled, getEntangledPair
 * 12. Admin & Management Functions: pause, unpause, setMeasurementCooldown, setDecoherenceRate, setEntanglementFee, withdrawFees, updateTokenURI
 * 13. Internal Helper Functions: _generateSuperposition, _calculateDecayFactor, _applyEntanglementEffect, _updateKeyAccessLevel
 *
 * Function Summary:
 * - constructor(): Initializes contract.
 * - pause(): Pauses contract (Owner).
 * - unpause(): Unpauses contract (Owner).
 * - mintKey(): Mints a new key.
 * - measureSuperposition(uint256 tokenId): Observes key, fixes state.
 * - applyDecoherence(uint256 tokenId): Applies time-decay to state.
 * - entangleKeys(uint256 tokenId1, uint256 tokenId2): Links two keys (Payable).
 * - disentangleKeys(uint256 tokenId): Unlinks a key.
 * - observeEntangledState(uint256 tokenId): Measures entangled key, potentially affecting pair.
 * - getAccessLevel(uint256 tokenId): Gets effective utility level. (View)
 * - getKeyDetails(uint256 tokenId): Gets all key data. (View)
 * - calculatePotentialAccessLevel(uint256 tokenId, uint256 assumedMeasuredState): Hypothetical access level calculation. (View)
 * - getCurrentDecayFactor(uint256 tokenId): Gets current decay multiplier. (View)
 * - getTimeSinceLastObservation(uint256 tokenId): Gets time since last measurement. (View)
 * - isEntangled(uint256 tokenId): Checks entanglement status. (View)
 * - getEntangledPair(uint256 tokenId): Gets entangled pair ID. (View)
 * - setMeasurementCooldown(uint256 cooldownSeconds): Sets measurement cooldown (Owner).
 * - setDecoherenceRate(uint256 rate): Sets decay rate (Owner).
 * - setEntanglementFee(uint256 fee): Sets entanglement fee (Owner).
 * - withdrawFees(): Withdraws fees (Owner).
 * - updateTokenURI(string memory baseURI): Sets base URI (Owner).
 * - balanceOf(address owner): ERC721. (View)
 * - ownerOf(uint256 tokenId): ERC721. (View)
 * - transferFrom(address from, address to, uint256 tokenId): ERC721.
 * - safeTransferFrom(address from, address to, uint256 tokenId): ERC721.
 * - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): ERC721.
 * - approve(address to, uint256 tokenId): ERC721.
 * - setApprovalForAll(address operator, bool approved): ERC721.
 * - getApproved(uint256 tokenId): ERC721. (View)
 * - isApprovedForAll(address owner, address operator): ERC721. (View)
 * - tokenURI(uint256 tokenId): ERC721 (Dynamic). (View)
 * - supportsInterface(bytes4 interfaceId): ERC165. (View)
 * - name(): ERC721. (View)
 * - symbol(): ERC721. (View)
 * - totalSupply(): ERC721 Enumerable. (View)
 * - tokenByIndex(uint256 index): ERC721 Enumerable. (View)
 * - tokenOfOwnerByIndex(address owner, uint256 index): ERC721 Enumerable. (View)
 */
contract QuantumKeyNFT is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error KeyDoesNotExist(uint256 tokenId);
    error NotSuperpositionState(uint256 tokenId);
    error AlreadyMeasured(uint256 tokenId);
    error MeasurementCooldownActive(uint256 tokenId, uint256 timeRemaining);
    error KeyAlreadyEntangled(uint256 tokenId);
    error KeysAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error NotEntangled(uint256 tokenId);
    error SelfEntanglement();
    error InvalidEntanglementPair(uint256 tokenId1, uint256 tokenId2);
    error NotOwnerOrApproved(uint256 tokenId);
    error InsufficientEntanglementFee(uint256 requiredFee);
    error ZeroAddress();
    error ZeroAmount();
    error ZeroValueForRate();

    // --- Events ---
    event KeyMinted(uint256 indexed tokenId, address indexed owner);
    event KeyMeasured(uint256 indexed tokenId, uint256 indexed measuredState, uint256 observationTime);
    event DecoherenceApplied(uint256 indexed tokenId, uint256 decayFactor);
    event KeysEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 timestamp);
    event KeyDisentangled(uint256 indexed tokenId, uint256 timestamp);
    event EntangledStateObserved(uint256 indexed tokenId, uint256 indexed entangledTokenId, uint256 observationTime);
    event MeasurementCooldownUpdated(uint256 newCooldown);
    event DecoherenceRateUpdated(uint256 newRate);
    event EntanglementFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // --- Structs ---

    // Represents the quantum state of a key
    // superpositionState: Represents potential outcomes before measurement
    // currentState: The fixed outcome after measurement
    // accessLevel: The effective utility derived from state and decay
    struct KeyData {
        uint256 creationTime;
        uint256 lastObservationTime; // Timestamp of last measurement or entanglement observation
        uint256 entropyFactor;       // Pseudorandomness seed component
        uint256[] superpositionState; // Array of possible values before measurement
        uint256 currentState;        // The value after measurement (0 if still in superposition)
        uint256 accessLevel;         // Calculated utility value
        uint256 entangledTokenId;    // Token ID of the entangled key (0 if not entangled)
    }

    // --- State Variables ---

    mapping(uint256 => KeyData) private _keyData;
    string private _baseTokenURI;

    uint256 public measurementCooldown = 1 days; // Time before a key can be measured again
    uint256 public decoherenceRate = 100;     // Rate of decay (e.g., 100 = 1% decay per unit time, scaled)
    uint256 public entanglementFee = 0 ether; // Fee to entangle two keys

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
    }

    // --- Modifiers ---

    modifier onlyKeyOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotOwnerOrApproved(tokenId);
        }
        _;
    }

    // --- Core Quantum Logic Functions ---

    /**
     * @dev Mints a new Quantum Key NFT.
     * The new key starts in a superposition state.
     */
    function mintKey() public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Pseudorandomness source (simple demonstration)
        uint256 _entropyFactor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty, newTokenId)));

        KeyData memory newKey = KeyData({
            creationTime: block.timestamp,
            lastObservationTime: 0, // Starts in superposition
            entropyFactor: _entropyFactor,
            superpositionState: _generateSuperposition(_entropyFactor), // Generate possible states
            currentState: 0, // 0 indicates superposition
            accessLevel: 0,  // Access level starts low or 0 until measured
            entangledTokenId: 0
        });

        _safeMint(msg.sender, newTokenId);
        _keyData[newTokenId] = newKey;

        // Calculate initial access level (e.g., based on creation time or initial state)
        // For simplicity, access is 0 until measured.

        emit KeyMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    /**
     * @dev "Measures" a key's superposition, fixing its currentState.
     * Can only be called if the key is in superposition and cooldown has passed.
     * Applies decay after measurement.
     */
    function measureSuperposition(uint256 tokenId) public whenNotPaused onlyKeyOwnerOrApproved(tokenId) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        if (key.currentState != 0) revert AlreadyMeasured(tokenId);
        if (key.lastObservationTime > 0 && block.timestamp < key.lastObservationTime + measurementCooldown) {
            revert MeasurementCooldownActive(tokenId, key.lastObservationTime + measurementCooldown - block.timestamp);
        }
        if (key.superpositionState.length == 0) revert NotSuperpositionState(tokenId); // Should not happen if minted correctly

        // Simulate "collapse" to one state using pseudorandomness
        // More sophisticated PRF/VRF would be needed for truly unpredictable outcome
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, key.entropyFactor, tokenId, key.lastObservationTime)));
        uint256 chosenIndex = seed % key.superpositionState.length;
        key.currentState = key.superpositionState[chosenIndex];

        key.lastObservationTime = block.timestamp;
        // Clear superposition state as it has collapsed
        delete key.superpositionState; // Frees memory

        // Immediately apply decay based on the measurement time
        _updateKeyAccessLevel(tokenId);

        emit KeyMeasured(tokenId, key.currentState, block.timestamp);

        // If entangled, trigger potential effect on entangled pair
        if (key.entangledTokenId != 0) {
            _applyEntanglementEffect(tokenId, key.entangledTokenId);
        }
    }

    /**
     * @dev Explicitly applies time-based decay to a key's state and updates its access level.
     * Can be called by anyone to refresh a key's decay status on-chain.
     */
    function applyDecoherence(uint256 tokenId) public whenNotPaused {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        // Decoherence only applies after a state has been measured
        if (key.currentState == 0) revert NotSuperpositionState(tokenId);

        // Recalculate and update access level based on current time
        _updateKeyAccessLevel(tokenId);

        emit DecoherenceApplied(tokenId, getCurrentDecayFactor(tokenId));
    }


    /**
     * @dev Entangles two Quantum Keys. Requires payment of the entanglement fee.
     * Both keys must exist, not be already entangled, and not be the same key.
     * Requires approval for *both* keys by the sender if not the owner of both.
     */
    function entangleKeys(uint256 tokenId1, uint256 tokenId2) public payable whenNotPaused {
        if (tokenId1 == tokenId2) revert SelfEntanglement();
        if (msg.value < entanglementFee) revert InsufficientEntanglementFee(entanglementFee);

        KeyData storage key1 = _keyData[tokenId1];
        KeyData storage key2 = _keyData[tokenId2];

        if (key1.creationTime == 0) revert KeyDoesNotExist(tokenId1);
        if (key2.creationTime == 0) revert KeyDoesNotExist(tokenId2);

        if (key1.entangledTokenId != 0 || key2.entangledTokenId != 0) revert KeysAlreadyEntangled(tokenId1, tokenId2);

        // Check ownership/approval for both keys
        if (ownerOf(tokenId1) != msg.sender && !isApprovedForAll(ownerOf(tokenId1), msg.sender) && getApproved(tokenId1) != msg.sender) {
             revert NotOwnerOrApproved(tokenId1);
        }
         if (ownerOf(tokenId2) != msg.sender && !isApprovedForAll(ownerOf(tokenId2), msg.sender) && getApproved(tokenId2) != msg.sender) {
             revert NotOwnerOrApproved(tokenId2);
        }

        key1.entangledTokenId = tokenId2;
        key2.entangledTokenId = tokenId1;

        // Entangling might affect observation time or state synchronization
        // For simplicity here, let's update last observation time to now for potential linked effects
        key1.lastObservationTime = block.timestamp;
        key2.lastObservationTime = block.timestamp;

        // Recalculate access levels based on new entanglement status
        _updateKeyAccessLevel(tokenId1);
        _updateKeyAccessLevel(tokenId2);

        emit KeysEntangled(tokenId1, tokenId2, block.timestamp);

        // Fee is automatically held by the contract, can be withdrawn by owner
    }

    /**
     * @dev Breaks the entanglement link for a key.
     * Requires ownership or approval.
     */
    function disentangleKeys(uint256 tokenId) public whenNotPaused onlyKeyOwnerOrApproved(tokenId) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        if (key.entangledTokenId == 0) revert NotEntangled(tokenId);

        uint256 entangledPairId = key.entangledTokenId;
        KeyData storage entangledPair = _keyData[entangledPairId];
        if (entangledPair.entangledTokenId != tokenId) revert InvalidEntanglementPair(tokenId, entangledPairId); // Safety check

        key.entangledTokenId = 0;
        entangledPair.entangledTokenId = 0;

        // Recalculate access levels as entanglement is broken
        _updateKeyAccessLevel(tokenId);
        _updateKeyAccessLevel(entangledPairId);

        emit KeyDisentangled(tokenId, block.timestamp);
    }

    /**
     * @dev Attempts to observe the state of an entangled key, which might influence
     * the state or observation time of its entangled pair.
     * Requires ownership or approval.
     * Can be called even if the key was previously measured, refreshing the observation time.
     */
    function observeEntangledState(uint256 tokenId) public whenNotPaused onlyKeyOwnerOrApproved(tokenId) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        if (key.entangledTokenId == 0) revert NotEntangled(tokenId);

        uint256 entangledPairId = key.entangledTokenId;
        KeyData storage entangledPair = _keyData[entangledPairId];

        // Update observation times for both keys upon observation
        key.lastObservationTime = block.timestamp;
        entangledPair.lastObservationTime = block.timestamp;

        // Apply potential entanglement effects (e.g., minor state shift, shared decay reset)
        _applyEntanglementEffect(tokenId, entangledPairId);

        // Recalculate access levels
        _updateKeyAccessLevel(tokenId);
        _updateKeyAccessLevel(entangledPairId);


        emit EntangledStateObserved(tokenId, entangledPairId, block.timestamp);
    }


    // --- Utility & State Query Functions ---

    /**
     * @dev Returns the comprehensive data struct for a given key.
     * Allows querying all state variables.
     */
    function getKeyDetails(uint256 tokenId) public view returns (KeyData memory) {
        if (_keyData[tokenId].creationTime == 0) revert KeyDoesNotExist(tokenId);
        return _keyData[tokenId];
    }

    /**
     * @dev Calculates and returns the current effective access level of a key.
     * Takes into account the measured state (if any) and current decay.
     */
    function getAccessLevel(uint256 tokenId) public view returns (uint256) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);

        // If in superposition, access level might be 0 or some default
        if (key.currentState == 0) {
            return 0; // Access is only granted from a measured state
        }

        // Calculate decay factor
        uint256 decayFactor = _calculateDecayFactor(tokenId);

        // Apply decay to the current state to get the effective access level
        // Example: accessLevel = currentState * (10000 - decayFactor) / 10000
        // decayFactor is measured in basis points (0-10000) for 0-100% decay
        uint256 effectiveState = (key.currentState * (10000 - decayFactor)) / 10000;

        // Further modifiers could be added here (e.g., entanglement bonus/penalty)

        return effectiveState;
    }

     /**
     * @dev Calculates what the access level *would be* if the key was measured
     * into a specific hypothetical state, considering current decay.
     * Useful for predicting outcomes before measurement.
     */
    function calculatePotentialAccessLevel(uint256 tokenId, uint256 assumedMeasuredState) public view returns (uint256) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);

        uint256 decayFactor = _calculateDecayFactor(tokenId);

        // Apply decay to the assumed state
        uint256 potentialAccess = (assumedMeasuredState * (10000 - decayFactor)) / 10000;

        return potentialAccess;
    }

    /**
     * @dev Returns the current decay multiplier for a key in basis points (0-10000).
     * 0 = no decay, 10000 = 100% decay.
     * Based on time since last observation.
     */
    function getCurrentDecayFactor(uint256 tokenId) public view returns (uint256) {
         KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        // Decay only applies after measurement
        if (key.currentState == 0 && key.entangledTokenId == 0) return 0; // No decay in superposition or if never observed

        return _calculateDecayFactor(tokenId);
    }

    /**
     * @dev Returns the time elapsed since the key was last measured or observed (if entangled).
     * Returns 0 if never measured/observed (still in superposition).
     */
    function getTimeSinceLastObservation(uint256 tokenId) public view returns (uint256) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        if (key.lastObservationTime == 0) return 0; // Never measured/observed

        return block.timestamp - key.lastObservationTime;
    }

     /**
     * @dev Checks if a key is currently entangled.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
         KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        return key.entangledTokenId != 0;
    }

    /**
     * @dev Returns the token ID of the key's entangled partner.
     * Returns 0 if the key is not entangled.
     */
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        KeyData storage key = _keyData[tokenId];
        if (key.creationTime == 0) revert KeyDoesNotExist(tokenId);
        return key.entangledTokenId;
    }


    // --- Admin & Management Functions ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     * Prevents minting and certain state changes.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

     /**
     * @dev Sets the cooldown period between measurements. Only callable by the owner.
     */
    function setMeasurementCooldown(uint256 cooldownSeconds) public onlyOwner {
        measurementCooldown = cooldownSeconds;
        emit MeasurementCooldownUpdated(cooldownSeconds);
    }

    /**
     * @dev Sets the rate at which key state decays over time. Only callable by the owner.
     * Rate is in basis points (0-10000) relative to a time unit (e.g., per day, based on calculation logic).
     */
    function setDecoherenceRate(uint256 rate) public onlyOwner {
        if (rate > 10000) revert ZeroValueForRate(); // Prevent rate > 100% per time unit (adjust if needed)
        decoherenceRate = rate;
        emit DecoherenceRateUpdated(rate);
    }

     /**
     * @dev Sets the fee required to entangle two keys. Only callable by the owner.
     * Fee is in native token (ether).
     */
    function setEntanglementFee(uint256 fee) public onlyOwner {
        entanglementFee = fee;
        emit EntanglementFeeUpdated(fee);
    }

    /**
     * @dev Allows the contract owner to withdraw collected entanglement fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroAmount();

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Transfer failed");

        emit FeesWithdrawn(owner(), balance);
    }

    /**
     * @dev Allows the contract owner to update the base token URI.
     * Token URIs are constructed as baseURI + tokenId.
     */
    function updateTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        // Note: ERC721MetadataURI has a protected _setTokenURI, but ERC721Enumerable doesn't.
        // We override tokenURI() below to use the dynamic base URI.
    }


    // --- ERC721 and ERC721Enumerable Overrides ---

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

     /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Appends tokenId to the base URI. An off-chain service is expected
     * to handle dynamic metadata based on the key's on-chain state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721.URIQueryForNonexistentToken();
        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // The following functions are overrides required by Solidity.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates a potential superposition state based on an entropy factor.
     * In a real system, this might involve more complex random number generation or oracle calls.
     * For simulation, it creates a simple array of possible outcomes.
     */
    function _generateSuperposition(uint256 entropyFactor) internal pure returns (uint256[] memory) {
        uint256 numStates = 2 + (entropyFactor % 3); // 2 to 4 possible states
        uint256[] memory potentialStates = new uint256[](numStates);

        for (uint i = 0; i < numStates; i++) {
            // Generate potential values based on entropy and index
            potentialStates[i] = uint256(keccak256(abi.encodePacked(entropyFactor, i))) % 1000 + 1; // Values between 1 and 1000
        }
        return potentialStates;
    }

    /**
     * @dev Calculates the current decay factor for a key based on time since last observation.
     * Decay increases linearly (or could be exponential in a more complex model) with time.
     * Returns decay in basis points (0-10000).
     */
    function _calculateDecayFactor(uint256 tokenId) internal view returns (uint256) {
        KeyData storage key = _keyData[tokenId];
        if (key.lastObservationTime == 0) return 0; // No decay if never observed/measured

        uint256 timeSinceObservation = block.timestamp - key.lastObservationTime;

        // Simple linear decay: decay = (time elapsed * decoherence rate) / time unit
        // Let's assume decoherenceRate is basis points per day for simplicity calculation
        // Time unit = 1 day (86400 seconds)
        uint224 timeUnit = 86400; // 1 day in seconds

        // Ensure we don't overflow when multiplying
        // decay = (timeSinceObservation * decoherenceRate) / timeUnit
        uint256 potentialDecay = (timeSinceObservation * decoherenceRate);

        // Prevent division by zero if timeUnit is 0 (shouldn't happen with 86400)
        uint256 currentDecay = (timeUnit == 0) ? potentialDecay : potentialDecay / timeUnit;


        // Cap decay at 100% (10000 basis points)
        return Math.min(currentDecay, 10000);
    }

     /**
     * @dev Internal function to apply effects between entangled keys.
     * Currently, just updates observation times. Could be expanded for state influence.
     */
    function _applyEntanglementEffect(uint256 tokenId1, uint256 tokenId2) internal {
         KeyData storage key1 = _keyData[tokenId1];
         KeyData storage key2 = _keyData[tokenId2];

         // Example effect: Sync observation times (already done in external functions)
         // Example effect: If one is measured, slightly influence the other's next measurement or current state.
         // This is a placeholder; complex entanglement simulation is beyond simple Solidity.
         // For example, you could average states, or make measuring one trigger a partial decay reset on the other.
         key1.lastObservationTime = block.timestamp; // Ensure sync
         key2.lastObservationTime = block.timestamp; // Ensure sync
     }

     /**
      * @dev Internal function to recalculate and update the access level for a key.
      * Called after measurement, entanglement, disentanglement, or decay application.
      */
     function _updateKeyAccessLevel(uint256 tokenId) internal {
         KeyData storage key = _keyData[tokenId];
         // Access level depends on measured state and current decay
         key.accessLevel = getAccessLevel(tokenId); // Re-calculate using the getter logic
     }

     // Fallback to receive Ether for entanglement fees
     receive() external payable {}
}
```

**Explanation of Design Choices & Limitations:**

1.  **Quantum Simulation:** This contract *simulates* quantum concepts. It does *not* use actual quantum computing or cryptography. Superposition is an array, measurement is picking from the array, entanglement is a linked ID, and decay is a time-based calculation. This abstraction allows modeling interesting state dynamics on a blockchain.
2.  **Pseudorandomness:** Blockchain is deterministic. Using `block.timestamp`, `block.difficulty`, `msg.sender`, etc., provides *pseudorandomness* suitable for conceptual simulation but is *not* secure or truly unpredictable. For production, Chainlink VRF or similar is necessary for secure randomness.
3.  **Dynamic Metadata:** The `tokenURI` points to a base URI + tokenId. A separate off-chain service (an API or server) would need to listen to contract events (`KeyMeasured`, `DecoherenceApplied`, `KeysEntangled`, etc.) and maintain a database of each key's state to serve up dynamic JSON metadata reflecting its current `currentState`, `decayFactor`, `isEntangled` status, etc.
4.  **Decay Model:** The decay model is simple linear decay based on time since last observation. More complex models (exponential, threshold-based) are possible. The `decoherenceRate` is a parameter allowing tuning. `applyDecoherence` is callable by anyone to update a key's on-chain state, incentivizing external calls to keep the state fresh.
5.  **Access Level:** The `accessLevel` is a calculated property. Its actual "utility" would be implemented in *other* contracts or off-chain applications that integrate with this NFT, calling `getAccessLevel` to determine what actions or access the key grants.
6.  **Entanglement Fee:** The `entangleKeys` function is `payable` and requires a fee. This adds a small DeFi/economic element and necessitates the `withdrawFees` function.
7.  **Function Count:** By including standard ERC721/Enumerable functions alongside the custom quantum logic, management, and query functions, we easily exceed the 20-function requirement.

This contract provides a framework for dynamic, interactive NFTs with a unique theme, going beyond simple digital collectibles.