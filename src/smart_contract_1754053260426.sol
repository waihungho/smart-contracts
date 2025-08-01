This smart contract, "QuantumLeapNFT," introduces a novel concept for dynamic, evolving NFTs inspired by quantum mechanics. Instead of static images, these NFTs represent theoretical "Quantum States" that possess properties like `coherence` (stability), `entanglement` (connection to other NFTs), and a susceptibility to a global `quantumFlux` (environmental influence). Users can "observe" an NFT to momentarily lock its state, or "entangle" it with another, leading to shared fates. The ultimate goal is to guide an NFT through its "quantum evolution" to achieve a "Quantum Leap," a significant, irreversible transformation.

---

## QuantumLeapNFT: Contract Outline & Function Summary

This contract implements a dynamic NFT system based on conceptual quantum mechanics. NFTs have properties like `coherence` (decaying over time if unobserved), `entanglement` (links to other NFTs), and are influenced by a global `quantumFlux`.

### I. Core ERC-721 Standard Functions

These are the standard functions inherited/overridden from OpenZeppelin's ERC721 contract, providing basic NFT functionality. While essential, they are not counted towards the "20 advanced concept" functions.

*   `balanceOf(address owner)`: Returns the number of NFTs owned by `owner`.
*   `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId`.
*   `approve(address to, uint256 tokenId)`: Approves `to` to take ownership of `tokenId`.
*   `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId`.
*   `setApprovalForAll(address operator, bool approved)`: Sets or unsets approval for an operator to manage all of `msg.sender`'s NFTs.
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of `owner`'s NFTs.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer variant.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)`: Overloaded safe transfer variant.
*   `supportsInterface(bytes4 interfaceId)`: Standard EIP-165 support.
*   `name()`: Returns the NFT collection name.
*   `symbol()`: Returns the NFT collection symbol.

### II. Quantum Mechanics & Dynamic NFT Logic Functions (22 Functions)

These functions embody the unique "QuantumLeapNFT" concept, allowing for dynamic state changes, user interactions, and admin control over the quantum environment.

1.  **`initiateQuantumLeapNFT(address to, string memory baseURI)`**
    *   **Description:** Mints a new QuantumLeap NFT to the specified address. It starts in an "unobserved" state with full coherence, ready for quantum evolution.
    *   **Concept:** Represents the genesis of a new quantum state or research path.
    *   **Access:** `onlyOwner`.

2.  **`tokenURI(uint256 tokenId)`**
    *   **Description:** Returns the metadata URI for a given token. This is highly dynamic, reflecting its current coherence, entanglement status, and whether it's observed. It simulates the "quantum state" of the NFT.
    *   **Concept:** Superposition (potential states) vs. Observation (fixed state) reflected in metadata.

3.  **`observeQuantumState(uint256 tokenId)`**
    *   **Description:** "Observes" the quantum state of an NFT. This action temporarily locks its current properties, prevents coherence decay for a set duration, and updates its metadata URI to a "collapsed" form. Costs gas.
    *   **Concept:** Analogous to wave function collapse in quantum mechanics, fixing a state.
    *   **Access:** Anyone (owner of token or approved).

4.  **`getCurrentCoherence(uint256 tokenId)`**
    *   **Description:** Calculates and returns the current coherence level of an NFT. Coherence decays over time if the NFT is unobserved.
    *   **Concept:** Quantum coherence as a measure of a system's "purity" or stability.
    *   **Access:** `view` (anyone).

5.  **`getTimeUntilNextObservationPossible(uint256 tokenId)`**
    *   **Description:** Returns the remaining time in seconds before an observed NFT can be observed again.
    *   **Concept:** Cooldown period after state collapse.
    *   **Access:** `view` (anyone).

6.  **`boostCoherence(uint256 tokenId)`**
    *   **Description:** Allows the owner of an NFT to spend Ether to instantly increase its coherence level.
    *   **Concept:** Injecting energy into a quantum system to restore its coherence.
    *   **Access:** Owner of token or approved.

7.  **`requestEntanglement(uint256 tokenIdA, uint256 tokenIdB)`**
    *   **Description:** Initiates an entanglement request between two NFTs. Both NFTs must be owned by the caller. Requires Ether payment.
    *   **Concept:** Creating a quantum entanglement link between two entities.
    *   **Access:** Owner of both tokens or approved.

8.  **`acceptEntanglement(uint256 tokenIdA, uint256 tokenIdB)`**
    *   **Description:** Confirms an entanglement request. This is part of a two-step process (for more complex scenarios where owners might differ, though here `request` implies same owner). Finalizes the entanglement.
    *   **Concept:** Mutual agreement to form an entangled pair.
    *   **Access:** Owner of both tokens or approved.

9.  **`breakEntanglement(uint256 tokenId)`**
    *   **Description:** Disentangles an NFT from its partner. This action also costs Ether.
    *   **Concept:** Decoherence or breaking an entanglement bond.
    *   **Access:** Owner of token or approved.

10. **`getEntangledPartner(uint256 tokenId)`**
    *   **Description:** Returns the ID of the NFT currently entangled with the specified `tokenId`, or 0 if not entangled.
    *   **Concept:** Querying an entanglement relationship.
    *   **Access:** `view` (anyone).

11. **`updateGlobalQuantumFlux()`**
    *   **Description:** Callable by the contract owner, this function updates a global `fluxModifier` which influences the outcome or properties of *unobserved* NFTs over time.
    *   **Concept:** Simulating external environmental factors affecting quantum states.
    *   **Access:** `onlyOwner`.

12. **`getFluxModifier()`**
    *   **Description:** Returns the current global `fluxModifier`.
    *   **Concept:** Observing the global quantum environment.
    *   **Access:** `view` (anyone).

13. **`performQuantumLeap(uint256 tokenId)`**
    *   **Description:** The ultimate action. If an NFT meets high coherence requirements and the owner pays the `quantumLeapCost`, the NFT undergoes a significant, irreversible transformation, updating its `baseURI` permanently.
    *   **Concept:** A major, irreversible state change, akin to a phase transition or breakthrough.
    *   **Access:** Owner of token or approved.

14. **`getSimulatedFutureStateURI(uint256 tokenId)`**
    *   **Description:** A pure function that simulates what the `tokenURI` might look like if a Quantum Leap were performed at this moment, without actually performing it.
    *   **Concept:** Predicting potential outcomes based on current state and flux.
    *   **Access:** `view` (anyone).

15. **`refreshObservedTokenURI(uint256 tokenId)`**
    *   **Description:** Allows the owner to refresh the URI of an *observed* NFT, useful if the underlying metadata system has dynamic elements tied to on-chain state.
    *   **Concept:** Updating the "observed reality" of an NFT.
    *   **Access:** Owner of token or approved.

16. **`setCoherenceDecayRate(uint256 _newRate)`**
    *   **Description:** Sets the rate at which an unobserved NFT's coherence decays over time.
    *   **Concept:** Admin control over the "stability" of quantum states.
    *   **Access:** `onlyOwner`.

17. **`setObservationLockDuration(uint256 _newDuration)`**
    *   **Description:** Sets the duration for which an NFT's state is locked after being observed.
    *   **Concept:** Admin control over how long a state collapse endures.
    *   **Access:** `onlyOwner`.

18. **`setEntanglementCost(uint256 _newCost)`**
    *   **Description:** Sets the Ether cost for initiating or breaking an entanglement.
    *   **Concept:** Admin control over the energy required for quantum interactions.
    *   **Access:** `onlyOwner`.

19. **`setQuantumLeapCost(uint256 _newCost)`**
    *   **Description:** Sets the Ether cost for performing a "Quantum Leap."
    *   **Concept:** Admin control over the energy barrier for major transformations.
    *   **Access:** `onlyOwner`.

20. **`pause()`**
    *   **Description:** Pauses core contract functionalities (minting, observation, entanglement, leaps).
    *   **Concept:** Emergency stop for the quantum system.
    *   **Access:** `onlyOwner`.

21. **`unpause()`**
    *   **Description:** Unpauses the contract functionalities.
    *   **Concept:** Resuming quantum evolution.
    *   **Access:** `onlyOwner`.

22. **`withdrawFunds()`**
    *   **Description:** Allows the contract owner to withdraw accumulated Ether from entanglement fees and leap costs.
    *   **Concept:** Managing the economic aspect of the quantum system.
    *   **Access:** `onlyOwner`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title QuantumLeapNFT
 * @dev A dynamic NFT contract inspired by quantum mechanics.
 * NFTs represent 'Quantum States' with coherence, entanglement, and flux.
 * Users can 'observe' to stabilize, 'entangle' for linked states,
 * and aim for a 'Quantum Leap' (major transformation).
 */
contract QuantumLeapNFT is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- Custom Errors ---
    error InvalidTokenId();
    error NotTokenOwnerOrApproved();
    error CooldownPeriodActive();
    error NotEnoughCoherenceForLeap();
    error AlreadyEntangled();
    error NotEntangled();
    error EntanglementRequestNotFound();
    error NotEnoughFunds();
    error EntanglementTargetMismatch();
    error CannotEntangleWithSelf();
    error TokenAlreadyObserved(); // Can't observe if it's permanently observed after a Leap
    error NotAnObservedToken(); // Can't refresh URI if it's not in an observed/locked state

    // --- State Variables & Mappings ---

    // Struct to store quantum state properties of each NFT
    struct QuantumState {
        uint256 coherence;            // Current coherence level (0-10000, 10000 = max)
        uint64 lastObservedTimestamp; // Timestamp of last observation
        uint64 observationLockUntil;  // Timestamp until which observation prevents decay
        uint256 entanglementPartnerId; // 0 if not entangled, otherwise the partner's tokenId
        bool isEntangled;             // True if this token is part of an entanglement pair
        bool hasPerformedLeap;        // True if the token has undergone a Quantum Leap
        string currentBaseURI;        // The base URI for this specific NFT (changes after leap)
    }

    mapping(uint256 => QuantumState) public quantumStates;
    uint256 private _nextTokenId; // Counter for unique token IDs

    // Global parameters
    uint256 public coherenceDecayRate;       // Coherence points lost per day (e.g., 100 for 1%)
    uint256 public observationLockDuration;  // Duration (seconds) an NFT is stable after observation
    uint256 public entanglementCost;         // Cost (in Wei) to initiate/break entanglement
    uint256 public quantumLeapCost;          // Cost (in Wei) to perform a Quantum Leap
    uint256 public quantumLeapMinCoherence;  // Minimum coherence required for a Quantum Leap

    uint256 public globalQuantumFluxModifier; // A global parameter affecting unobserved NFTs' potential

    // Mapping for two-step entanglement requests if different owners were desired, for now, simple 1-step
    // mapping(uint256 => uint256) private entanglementRequests; // tokenIdA => tokenIdB requesting entanglement

    // --- Events ---
    event NFTInitiated(uint256 indexed tokenId, address indexed owner, string baseURI);
    event ObservationMade(uint256 indexed tokenId, address indexed observer, uint256 finalCoherence);
    event CoherenceBoosted(uint256 indexed tokenId, uint256 newCoherence);
    event EntanglementCreated(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event QuantumLeapPerformed(uint256 indexed tokenId, string newURI);
    event GlobalQuantumFluxUpdated(uint256 newFluxModifier);
    event TokenURIUpdated(uint256 indexed tokenId, string newURI);


    /**
     * @dev Constructor
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     * @param initialCoherenceDecayRate Initial daily decay rate for coherence.
     * @param initialObservationLockDuration Initial duration an NFT state is locked after observation.
     * @param initialEntanglementCost Initial cost for entanglement operations.
     * @param initialQuantumLeapCost Initial cost for performing a quantum leap.
     * @param initialQuantumLeapMinCoherence Initial minimum coherence for a leap.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialCoherenceDecayRate,
        uint256 initialObservationLockDuration,
        uint256 initialEntanglementCost,
        uint256 initialQuantumLeapCost,
        uint256 initialQuantumLeapMinCoherence
    ) ERC721(name_, symbol_) Ownable(msg.sender) Pausable() {
        coherenceDecayRate = initialCoherenceDecayRate;
        observationLockDuration = initialObservationLockDuration;
        entanglementCost = initialEntanglementCost;
        quantumLeapCost = initialQuantumLeapCost;
        quantumLeapMinCoherence = initialQuantumLeapMinCoherence;
        globalQuantumFluxModifier = 0; // Initialize global flux
        _nextTokenId = 1; // Start token IDs from 1
    }

    // --- Public & External Functions (22 unique concept functions) ---

    /**
     * @dev 1. Initiates a new QuantumLeap NFT.
     * Starts with full coherence (10000) and an unobserved state.
     * @param to The address to mint the NFT to.
     * @param baseURI The initial base URI for this specific NFT.
     */
    function initiateQuantumLeapNFT(address to, string memory baseURI) external onlyOwner whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        quantumStates[tokenId] = QuantumState({
            coherence: 10000, // Full coherence initially
            lastObservedTimestamp: 0,
            observationLockUntil: 0,
            entanglementPartnerId: 0,
            isEntangled: false,
            hasPerformedLeap: false,
            currentBaseURI: baseURI
        });

        emit NFTInitiated(tokenId, to, baseURI);
        return tokenId;
    }

    /**
     * @dev 2. Returns the URI for a given token, dynamically reflecting its state.
     * Overrides ERC721's tokenURI to provide dynamic metadata.
     * Unobserved: Shows current coherence, potential for future states (influenced by flux).
     * Observed (locked): Shows the fixed, collapsed state.
     * Entangled: May show properties influenced by its partner.
     * Leaped: Shows its final, transformed state.
     * @param tokenId The ID of the token.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }

        QuantumState storage state = quantumStates[tokenId];
        string memory uriPrefix = state.currentBaseURI;
        string memory uriSuffix;

        if (state.hasPerformedLeap) {
            // After a leap, URI is permanent and reflects the transformed state.
            uriSuffix = string(abi.encodePacked("leaped/", tokenId.toString(), ".json"));
        } else if (state.observationLockUntil > block.timestamp) {
            // Observed and locked: Fixed state
            uriSuffix = string(abi.encodePacked("observed/", tokenId.toString(), ".json"));
        } else {
            // Unobserved (or lock expired): Dynamic state based on coherence, flux, and potential
            uint256 currentCoherence = _calculateCurrentCoherence(tokenId);
            uriSuffix = string(abi.encodePacked(
                "unobserved/",
                tokenId.toString(),
                "?coherence=", currentCoherence.toString(),
                "&flux=", globalQuantumFluxModifier.toString(),
                state.isEntangled ? string(abi.encodePacked("&entangled=", state.entanglementPartnerId.toString())) : ""
            ));
        }
        return string(abi.encodePacked(uriPrefix, uriSuffix));
    }

    /**
     * @dev 3. "Observes" the quantum state of an NFT.
     * This action prevents coherence decay for `observationLockDuration` and effectively
     * "collapses" its state temporarily, reflecting in its `tokenURI`.
     * @param tokenId The ID of the NFT to observe.
     */
    function observeQuantumState(uint256 tokenId) external payable whenNotPaused {
        if (msg.sender != ownerOf(tokenId) && !getApproved(tokenId) == msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
        QuantumState storage state = quantumStates[tokenId];
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (state.hasPerformedLeap) revert TokenAlreadyObserved(); // Can't observe a leaped token

        uint256 currentCoherence = _calculateCurrentCoherence(tokenId);

        // Update observation timestamps
        state.lastObservedTimestamp = uint64(block.timestamp);
        state.observationLockUntil = uint64(block.timestamp + observationLockDuration);
        state.coherence = currentCoherence; // Lock in the current coherence when observed

        emit ObservationMade(tokenId, msg.sender, currentCoherence);
    }

    /**
     * @dev 4. Calculates and returns the current coherence level of an NFT.
     * Coherence decays over time if the NFT is unobserved and not locked.
     * @param tokenId The ID of the NFT.
     * @return The current coherence level (0-10000).
     */
    function getCurrentCoherence(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _calculateCurrentCoherence(tokenId);
    }

    /**
     * @dev Internal helper to calculate current coherence, accounting for decay and observation lock.
     * @param tokenId The ID of the NFT.
     * @return The calculated current coherence.
     */
    function _calculateCurrentCoherence(uint256 tokenId) internal view returns (uint256) {
        QuantumState storage state = quantumStates[tokenId];
        if (state.hasPerformedLeap) {
            return 10000; // Leaped NFTs have max coherence (stable)
        }
        if (state.observationLockUntil > block.timestamp) {
            return state.coherence; // Coherence is locked during observation period
        }

        uint256 timeSinceLastActivity = block.timestamp - state.lastObservedTimestamp;
        uint256 decayAmount = (timeSinceLastActivity * coherenceDecayRate) / 1 days; // Decay per second

        if (state.coherence <= decayAmount) {
            return 0; // Coherence cannot go below zero
        } else {
            return state.coherence - decayAmount;
        }
    }

    /**
     * @dev 5. Returns the remaining time in seconds until an observed NFT can be observed again.
     * @param tokenId The ID of the NFT.
     * @return The remaining time in seconds.
     */
    function getTimeUntilNextObservationPossible(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        QuantumState storage state = quantumStates[tokenId];

        if (state.observationLockUntil > block.timestamp) {
            return state.observationLockUntil - block.timestamp;
        }
        return 0;
    }

    /**
     * @dev 6. Allows the owner to boost an NFT's coherence by paying Ether.
     * @param tokenId The ID of the NFT to boost.
     */
    function boostCoherence(uint256 tokenId) external payable whenNotPaused {
        if (msg.sender != ownerOf(tokenId) && !getApproved(tokenId) == msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
        if (!_exists(tokenId)) revert InvalidTokenId();
        QuantumState storage state = quantumStates[tokenId];
        if (state.hasPerformedLeap) revert TokenAlreadyObserved();

        // Calculate current coherence first
        state.coherence = _calculateCurrentCoherence(tokenId);

        // Boost amount depends on Ether sent. Simple 1:1 conversion for example.
        uint256 boostAmount = msg.value;
        uint256 newCoherence = state.coherence + (boostAmount / (entanglementCost / 100)); // Example: 100wei per 1 coherence point
        if (newCoherence > 10000) newCoherence = 10000;

        state.coherence = newCoherence;
        // Reset observation timestamp to reflect activity, but don't lock it
        state.lastObservedTimestamp = uint64(block.timestamp);

        emit CoherenceBoosted(tokenId, newCoherence);
    }

    /**
     * @dev 7. Initiates an entanglement request between two NFTs owned by the caller.
     * Requires both tokens to be unentangled.
     * @param tokenIdA The ID of the first NFT.
     * @param tokenIdB The ID of the second NFT.
     */
    function requestEntanglement(uint256 tokenIdA, uint256 tokenIdB) external payable whenNotPaused {
        if (msg.value < entanglementCost) revert NotEnoughFunds();
        if (tokenIdA == tokenIdB) revert CannotEntangleWithSelf();
        if (!_exists(tokenIdA) || !_exists(tokenIdB)) revert InvalidTokenId();
        if (ownerOf(tokenIdA) != msg.sender || ownerOf(tokenIdB) != msg.sender) revert NotTokenOwnerOrApproved(); // Both must be owned by caller

        QuantumState storage stateA = quantumStates[tokenIdA];
        QuantumState storage stateB = quantumStates[tokenIdB];

        if (stateA.isEntangled || stateB.isEntangled) revert AlreadyEntangled();
        if (stateA.hasPerformedLeap || stateB.hasPerformedLeap) revert TokenAlreadyObserved(); // Cannot entangle leaped tokens

        // For simplicity, we assume if request is made by single owner, it's accepted immediately
        // In a multi-owner scenario, this would be a pending request
        _createEntanglement(tokenIdA, tokenIdB);
    }

    /**
     * @dev 8. Accepts an entanglement request (simplified for single owner scenario).
     * @param tokenIdA The ID of the first NFT.
     * @param tokenIdB The ID of the second NFT.
     */
    function acceptEntanglement(uint256 tokenIdA, uint256 tokenIdB) external payable whenNotPaused {
        // In a single-owner scenario where `requestEntanglement` already links,
        // this function primarily serves as confirmation or for a more complex flow.
        // For this contract, it directly calls `_createEntanglement` with a check,
        // effectively making entanglement a one-step process if conditions met.

        if (msg.value < entanglementCost) revert NotEnoughFunds();
        if (tokenIdA == tokenIdB) revert CannotEntangleWithSelf();
        if (!_exists(tokenIdA) || !_exists(tokenIdB)) revert InvalidTokenId();
        if (ownerOf(tokenIdA) != msg.sender || ownerOf(tokenIdB) != msg.sender) revert NotTokenOwnerOrApproved();

        QuantumState storage stateA = quantumStates[tokenIdA];
        QuantumState storage stateB = quantumStates[tokenIdB];

        if (stateA.isEntangled || stateB.isEntangled) revert AlreadyEntangled();
        if (stateA.hasPerformedLeap || stateB.hasPerformedLeap) revert TokenAlreadyObserved();

        _createEntanglement(tokenIdA, tokenIdB);
    }

    /**
     * @dev Internal function to handle entanglement logic.
     */
    function _createEntanglement(uint256 tokenIdA, uint256 tokenIdB) internal {
        quantumStates[tokenIdA].entanglementPartnerId = tokenIdB;
        quantumStates[tokenIdA].isEntangled = true;
        quantumStates[tokenIdB].entanglementPartnerId = tokenIdA;
        quantumStates[tokenIdB].isEntangled = true;

        // Entanglement can prevent coherence decay to an extent, or link observations.
        // For simplicity, entangling resets lastObservedTimestamp but doesn't lock.
        quantumStates[tokenIdA].lastObservedTimestamp = uint64(block.timestamp);
        quantumStates[tokenIdB].lastObservedTimestamp = uint64(block.timestamp);

        emit EntanglementCreated(tokenIdA, tokenIdB);
    }

    /**
     * @dev 9. Breaks the entanglement of an NFT.
     * @param tokenId The ID of the NFT to disentangle.
     */
    function breakEntanglement(uint256 tokenId) external payable whenNotPaused {
        if (msg.value < entanglementCost) revert NotEnoughFunds();
        if (msg.sender != ownerOf(tokenId) && !getApproved(tokenId) == msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
        if (!_exists(tokenId)) revert InvalidTokenId();

        QuantumState storage state = quantumStates[tokenId];
        if (!state.isEntangled) revert NotEntangled();

        uint256 partnerId = state.entanglementPartnerId;
        QuantumState storage partnerState = quantumStates[partnerId];

        state.entanglementPartnerId = 0;
        state.isEntangled = false;
        partnerState.entanglementPartnerId = 0;
        partnerState.isEntangled = false;

        emit EntanglementBroken(tokenId, partnerId);
    }

    /**
     * @dev 10. Returns the entangled partner's tokenId for a given NFT.
     * @param tokenId The ID of the NFT.
     * @return The ID of the entangled partner, or 0 if not entangled.
     */
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0; // Return 0 if token doesn't exist
        return quantumStates[tokenId].entanglementPartnerId;
    }

    /**
     * @dev 11. Updates the global quantum flux modifier.
     * This modifier can influence how unobserved NFTs' properties are interpreted or evolve.
     * @param _newFluxModifier The new value for the global quantum flux modifier.
     */
    function updateGlobalQuantumFlux(uint256 _newFluxModifier) external onlyOwner {
        globalQuantumFluxModifier = _newFluxModifier;
        emit GlobalQuantumFluxUpdated(_newFluxModifier);
    }

    /**
     * @dev 12. Returns the current global quantum flux modifier.
     * @return The current global quantum flux modifier.
     */
    function getFluxModifier() public view returns (uint256) {
        return globalQuantumFluxModifier;
    }

    /**
     * @dev 13. Allows an NFT to undergo a "Quantum Leap," a permanent transformation.
     * Requires high coherence and payment. Changes the NFT's base URI.
     * @param tokenId The ID of the NFT to leap.
     */
    function performQuantumLeap(uint256 tokenId) external payable whenNotPaused {
        if (msg.value < quantumLeapCost) revert NotEnoughFunds();
        if (msg.sender != ownerOf(tokenId) && !getApproved(tokenId) == msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
        QuantumState storage state = quantumStates[tokenId];
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (state.hasPerformedLeap) revert TokenAlreadyObserved(); // Already leaped (observed permanently)

        uint256 currentCoherence = _calculateCurrentCoherence(tokenId);
        if (currentCoherence < quantumLeapMinCoherence) revert NotEnoughCoherenceForLeap();

        // Perform the leap: Update base URI and mark as leaped
        // The new URI could be derived from current coherence, global flux, and original URI
        string memory newLeapedURI = string(abi.encodePacked(
            "ipfs://new-leap-metadata-hash/", // Placeholder for actual new URI base
            tokenId.toString(),
            "/state-", currentCoherence.toString(),
            "-flux-", globalQuantumFluxModifier.toString(),
            ".json"
        ));
        
        state.currentBaseURI = newLeapedURI;
        state.hasPerformedLeap = true;
        state.coherence = 10000; // Leaped NFTs become maximally stable
        state.lastObservedTimestamp = uint64(block.timestamp); // Reset, now perpetually "observed"
        state.observationLockUntil = type(uint64).max; // Lock forever

        // If entangled, break entanglement upon leap for simplicity, or complex rules apply
        if (state.isEntangled) {
            uint256 partnerId = state.entanglementPartnerId;
            QuantumState storage partnerState = quantumStates[partnerId];
            state.entanglementPartnerId = 0;
            state.isEntangled = false;
            partnerState.entanglementPartnerId = 0;
            partnerState.isEntangled = false;
            emit EntanglementBroken(tokenId, partnerId);
        }

        emit QuantumLeapPerformed(tokenId, newLeapedURI);
    }

    /**
     * @dev 14. Provides a simulated future URI for an NFT if a Quantum Leap were performed now.
     * Does not alter the state of the NFT.
     * @param tokenId The ID of the NFT.
     * @return A string representing the simulated future URI.
     */
    function getSimulatedFutureStateURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        QuantumState storage state = quantumStates[tokenId];
        if (state.hasPerformedLeap) return state.currentBaseURI; // Already leaped, no future simulation

        uint256 currentCoherence = _calculateCurrentCoherence(tokenId);

        // Simulate the new URI based on current state parameters
        return string(abi.encodePacked(
            "ipfs://simulated-leap-metadata/", // Placeholder for simulation
            tokenId.toString(),
            "/coherence-", currentCoherence.toString(),
            "-flux-", globalQuantumFluxModifier.toString(),
            ".json"
        ));
    }

    /**
     * @dev 15. Refreshes the tokenURI for an NFT that is currently in an observed (locked) state.
     * This might be useful if the metadata backend has external dynamics not directly controlled by Solidity.
     * @param tokenId The ID of the NFT to refresh.
     */
    function refreshObservedTokenURI(uint256 tokenId) external whenNotPaused {
        if (msg.sender != ownerOf(tokenId) && !getApproved(tokenId) == msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert NotTokenOwnerOrApproved();
        }
        QuantumState storage state = quantumStates[tokenId];
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (state.observationLockUntil <= block.timestamp && !state.hasPerformedLeap) revert NotAnObservedToken();

        // Simply re-trigger `tokenURI` internally to ensure metadata reflects any subtle changes,
        // then emit an event for off-chain indexers to pick up.
        string memory currentUri = tokenURI(tokenId);
        emit TokenURIUpdated(tokenId, currentUri);
    }


    // --- Admin Functions ---

    /**
     * @dev 16. Sets the rate at which an unobserved NFT's coherence decays per day.
     * @param _newRate The new coherence decay rate (e.g., 100 for 1% per day).
     */
    function setCoherenceDecayRate(uint256 _newRate) external onlyOwner {
        coherenceDecayRate = _newRate;
    }

    /**
     * @dev 17. Sets the duration (in seconds) for which an NFT's state is locked after observation.
     * @param _newDuration The new observation lock duration.
     */
    function setObservationLockDuration(uint256 _newDuration) external onlyOwner {
        observationLockDuration = _newDuration;
    }

    /**
     * @dev 18. Sets the Ether cost for initiating or breaking an entanglement.
     * @param _newCost The new entanglement cost in Wei.
     */
    function setEntanglementCost(uint256 _newCost) external onlyOwner {
        entanglementCost = _newCost;
    }

    /**
     * @dev 19. Sets the Ether cost for performing a "Quantum Leap."
     * @param _newCost The new Quantum Leap cost in Wei.
     */
    function setQuantumLeapCost(uint256 _newCost) external onlyOwner {
        quantumLeapCost = _newCost;
    }

    /**
     * @dev Sets the minimum coherence required for an NFT to perform a Quantum Leap.
     * @param _minCoherence The new minimum coherence value.
     */
    function setQuantumLeapMinCoherence(uint256 _minCoherence) external onlyOwner {
        quantumLeapMinCoherence = _minCoherence;
    }

    /**
     * @dev 20. Pauses the contract, preventing certain actions.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev 21. Unpauses the contract, allowing actions again.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev 22. Allows the contract owner to withdraw accumulated Ether.
     */
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Overrides for Pausable Modifier ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, Pausable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // This contract assumes a base URI for each NFT. If the base URI for the collection
    // needs to be dynamic or globally controlled, that logic would be added here.
    // For this concept, `currentBaseURI` is tied to the specific NFT and changes only upon leap.
}
```