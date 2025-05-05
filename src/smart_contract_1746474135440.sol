Okay, let's design an interesting, advanced, and creative smart contract concept. We'll build upon the ERC721 standard but add complex state dynamics and interdependencies inspired by quantum mechanics concepts like *entanglement* and *superposition*.

This contract, which we can call `QuantumEntangledNFT`, will represent NFTs (let's call them 'Qubits') that can be entangled in pairs. Actions performed on one Qubit can instantly affect its entangled partner, regardless of who owns the partner. The Qubits will also have internal states that can change dynamically through 'quantum operations' and 'measurements', and a 'coherence' score that can be harvested but also decays over time.

This goes beyond standard ERC721 by:
1.  **Pair-based minting and management:** NFTs are created and often managed in entangled pairs.
2.  **Custom Transfer Logic:** Disallowing transfer of a single entangled NFT.
3.  **Dynamic State:** NFTs have internal state variables (`spin`, `energy`, `coherence`).
4.  **Entanglement Mechanics:** State changes on one entangled NFT affect its partner.
5.  **Quantum Operations:** Functions simulating quantum gates (`Hadamard`, `Cnot`) that modify state.
6.  **Measurement/Collapse:** A function simulating measurement that collapses superposition and affects state pseudo-randomly.
7.  **Time-based Decay/Harvest:** A coherence score that acts like a yield-bearing element but decays over time.
8.  **Complex Interdependence:** Actions on one NFT require checking the state/ownership of its partner.
9.  **Role-based Access Control:** Beyond owner/approved, introducing 'operators' for specific tasks.
10. **Dynamic Metadata:** Metadata potentially changing based on the internal state.

---

### Outline & Function Summary: QuantumEntangledNFT

**Contract Name:** `QuantumEntangledNFT`
**Inherits:** ERC721Enumerable, Ownable

**Core Concepts:**
*   **Qubit:** An individual NFT (ERC721 token).
*   **Entanglement:** Two Qubits linked together (`entangledPartners` mapping). Actions on one affect the other. Transfer of single entangled Qubits is restricted.
*   **Qubit State:** Internal state variables for each Qubit (`QubitState` struct: `spin`, `energyLevel`, `coherenceScore`, `isInSuperposition`, `lastStateChangeTime`).
*   **Quantum Operations:** Functions that deterministically change Qubit states, potentially affecting the entangled partner.
*   **Measurement:** A function that pseudo-randomly collapses superposition and affects the Qubit's state (and its partner's via entanglement).
*   **Coherence:** A score that can be harvested, but decays over time if not maintained or harvested.
*   **Operators:** Addresses granted permission to perform specific contract maintenance tasks (e.g., triggering coherence decay).

**Function Categories & Summary:**

1.  **ERC721 Standard (Inherited & Overridden):**
    *   `constructor`: Initializes the contract with name and symbol.
    *   `balanceOf(address owner)`: Returns the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a token.
    *   `approve(address to, uint256 tokenId)`: Gives permission to `to` to manage `tokenId`.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a single token.
    *   `setApprovalForAll(address operator, bool approved)`: Gives permission to `operator` to manage all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Checks if `operator` is approved for `owner`.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers token, checks entanglement.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data, checks entanglement.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer without data, checks entanglement.
    *   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: *Override* - Core logic to prevent transferring single entangled tokens.
    *   `tokenURI(uint256 tokenId)`: Returns URI for token metadata (dynamically generated based on state).
    *   `totalSupply()`: Returns total number of tokens minted.
    *   `tokenByIndex(uint256 index)`: Returns token ID by index.
    *   `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns token ID of owner by index.

2.  **Entanglement Management:**
    *   `mintEntangledPair(address owner)`: Mints two new Qubits, assigns them to `owner`, and entangles them. Initializes states. (Function 1 - Custom)
    *   `getEntangledPartner(uint256 tokenId)`: Returns the token ID of the entangled partner, or 0 if not entangled. (Function 2 - Custom)
    *   `isEntangled(uint256 tokenId)`: Checks if a Qubit is currently entangled. (Function 3 - Custom)
    *   `unEntanglePair(uint256 tokenId)`: Breaks the entanglement between a pair. Requires ownership of the Qubit or operator status. (Function 4 - Custom)
    *   `reEntanglePair(uint256 tokenId1, uint256 tokenId2)`: Attempts to entangle two previously un-entangled Qubits owned by the same address. (Function 5 - Custom)
    *   `burnEntangledPair(uint256 tokenId)`: Burns one Qubit and its entangled partner. Requires ownership or operator status. (Function 6 - Custom)

3.  **Qubit State Management & Operations:**
    *   `getQubitState(uint256 tokenId)`: Returns the current `QubitState` struct for a Qubit. (Function 7 - Custom)
    *   `getPairState(uint256 tokenId)`: Returns the `QubitState` for a Qubit and its entangled partner. (Function 8 - Custom)
    *   `superposeState(uint256 tokenId)`: Puts a non-entangled Qubit into a superposition state. (Function 9 - Custom)
    *   `applyHadamardGate(uint256 tokenId)`: Applies a simulated Hadamard gate, affecting the Qubit's state and potentially its entangled partner. (Function 10 - Custom)
    *   `applyCnotGate(uint256 controlTokenId, uint256 targetTokenId)`: Applies a simulated Controlled-NOT gate between two *entangled* Qubits. State change on target depends on control's state. (Function 11 - Custom)
    *   `swapStates(uint256 tokenId1, uint256 tokenId2)`: Swaps the full `QubitState` between two *entangled* Qubits. (Function 12 - Custom)
    *   `measureEntangledState(uint256 tokenId)`: Simulates measuring one Qubit in an entangled pair. Collapses superposition (if any) and pseudo-randomly updates both Qubits' states based on entanglement. (Function 13 - Custom)
    *   `bulkMeasure(uint256[] calldata tokenIds)`: Performs `measureEntangledState` on multiple token IDs efficiently. (Function 14 - Custom)

4.  **Coherence Mechanics:**
    *   `getCoherenceScore(uint256 tokenId)`: Returns the calculated current coherence score (decay applied). (Function 15 - Custom)
    *   `harvestCoherence(uint256 tokenId)`: Resets coherence score to 0 and potentially credits the owner with a calculated yield (e.g., based on the harvested score). (Function 16 - Custom)
    *   `decayCoherence(uint256 tokenId)`: Callable by anyone or operator; triggers coherence decay if due. (Function 17 - Custom)
    *   `boostCoherence(uint256 tokenId)`: Allows owner to increase coherence score (e.g., by paying a fee or using an external token). (Function 18 - Custom)

5.  **Access Control & Utilities:**
    *   `setBaseURI(string memory baseURI)`: Owner sets the base URI for token metadata. (Function 19 - Custom/Standard)
    *   `setAllowedOperator(address operator, bool approved)`: Owner grants/revokes 'Operator' role for specific maintenance functions (like `decayCoherence`). (Function 20 - Custom)
    *   `isAllowedOperator(address operator)`: Checks if an address has the 'Operator' role. (Function 21 - Custom)
    *   `setDecayRate(uint256 ratePerSecond)`: Owner sets the coherence decay rate. (Function 22 - Custom)
    *   `setHarvestYieldFactor(uint256 factor)`: Owner sets the factor for calculating yield from harvesting. (Function 23 - Custom)
    *   `renounceOwnership()`: Owner relinquishes ownership (standard).
    *   `transferOwnership(address newOwner)`: Owner transfers ownership (standard).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary provided above the code.

contract QuantumEntangledNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256;

    Counters.Counter private _tokenIdCounter;

    struct QubitState {
        uint8 spin; // Simplified state, e.g., 0 or 1
        uint256 energyLevel; // Arbitrary value representing energy
        uint256 coherenceScore; // A score that decays over time
        bool isInSuperposition; // Can be in superposition state
        uint256 lastStateChangeTime; // Timestamp of last significant state change/coherence update
    }

    // Mapping from tokenId to its entangled partner's tokenId (0 if not entangled)
    mapping(uint256 => uint256) private _entangledPartners;

    // Mapping from tokenId to its current state
    mapping(uint256 => QubitState) private _qubitStates;

    // Timestamp of the last coherence decay check for each token
    mapping(uint256 => uint256) private _lastCoherenceDecayCheck;

    // Addresses allowed to trigger certain maintenance functions (e.g., decay)
    mapping(address => bool) private _allowedOperators;

    // Configuration parameters
    uint256 public coherenceDecayRatePerSecond = 1; // Decay rate example (1 point per second)
    uint256 public harvestYieldFactor = 100; // Example: harvestScore * factor = yield units

    // Base URI for token metadata
    string private _baseURI;

    // Events
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event UnEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StateChanged(uint256 indexed tokenId, QubitState oldState, QubitState newState);
    event Measured(uint256 indexed tokenId, uint256 indexed partnerTokenId);
    event CoherenceHarvested(uint256 indexed tokenId, uint256 harvestedScore, uint256 yieldAmount);
    event CoherenceDecayed(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);
    event OperatorAllowed(address indexed operator, bool allowed);

    constructor(string memory name, string memory symbol)
        ERC721Enumerable(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Override ERC721Enumerable Functions ---

    /**
     * @dev See {ERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return super.tokenByIndex(index);
    }

    /**
     * @dev See {ERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {ERC721-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Requires that entangled tokens are not transferred individually.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        uint256 partnerId = _entangledPartners[tokenId];
        // If entangled, prevent single token transfers
        if (partnerId != 0) {
            // Check if the partner is also being transferred in this batch (not supported by this override structure for batches, but the core logic is single token)
            // For simplicity and safety, this contract DISALLOWS transferring *any* entangled token individually.
            // They must be un-entangled first.
            revert("QENT: Cannot transfer entangled tokens individually");
        }
        // Note: To enable transferring pairs, a custom batch transfer or a different entanglement check logic would be needed,
        // which is more complex and goes beyond a basic ERC721 override. This simple check enforces un-entanglement before transfer.
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * Dynamically generates metadata URI based on Qubit state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            return "";
        }

        // Note: Real dynamic metadata often involves an off-chain service
        // that serves JSON based on token ID and state queried from the contract.
        // This function returns a base URI + token ID. The off-chain service
        // would handle the dynamic part using getQubitState.
        // For this example, we'll just append state info to the URI (simplified).

        QubitState storage state = _qubitStates[tokenId];
        string memory uri = string(abi.encodePacked(
            _baseURI,
            tokenId.toString(),
            "?",
            "spin=", state.spin.toString(),
            "&energy=", state.energyLevel.toString(),
            "&coherence=", getCoherenceScore(tokenId).toString(), // Calculate decayed score
            "&superposition=", state.isInSuperposition ? "true" : "false",
            "&entangled=", _entangledPartners[tokenId] != 0 ? "true" : "false"
        ));
        return uri;
    }

    // --- Entanglement Management ---

    /**
     * @dev Mints two new Qubits, assigns them to owner, and entangles them.
     * Initializes their states.
     * Function 1: mintEntangledPair
     */
    function mintEntangledPair(address owner) public onlyOwner returns (uint256 tokenId1, uint256 tokenId2) {
        require(owner != address(0), "QENT: mint to the zero address");

        _tokenIdCounter.increment();
        tokenId1 = _tokenIdCounter.current();
        _safeMint(owner, tokenId1);

        _tokenIdCounter.increment();
        tokenId2 = _tokenIdCounter.current();
        _safeMint(owner, tokenId2);

        // Establish entanglement
        _entangledPartners[tokenId1] = tokenId2;
        _entangledPartners[tokenId2] = tokenId1;

        // Initialize states
        _qubitStates[tokenId1] = QubitState({
            spin: uint8(tokenId1 % 2), // Simple initial spin
            energyLevel: 100,
            coherenceScore: 500,
            isInSuperposition: false,
            lastStateChangeTime: block.timestamp
        });
        _qubitStates[tokenId2] = QubitState({
            spin: uint8(tokenId2 % 2),
            energyLevel: 100,
            coherenceScore: 500,
            isInSuperposition: false,
            lastStateChangeTime: block.timestamp
        });
        _lastCoherenceDecayCheck[tokenId1] = block.timestamp;
        _lastCoherenceDecayCheck[tokenId2] = block.timestamp;

        emit Entangled(tokenId1, tokenId2);
        emit StateChanged(tokenId1, QubitState(0,0,0,false,0), _qubitStates[tokenId1]); // Emit state init
        emit StateChanged(tokenId2, QubitState(0,0,0,false,0), _qubitStates[tokenId2]); // Emit state init
    }

    /**
     * @dev Returns the token ID of the entangled partner, or 0 if not entangled.
     * Function 2: getEntangledPartner
     */
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        return _entangledPartners[tokenId];
    }

    /**
     * @dev Checks if a Qubit is currently entangled.
     * Function 3: isEntangled
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return _entangledPartners[tokenId] != 0;
    }

    /**
     * @dev Breaks the entanglement between a pair. Requires ownership of one token or operator status.
     * Function 4: unEntanglePair
     */
    function unEntanglePair(uint256 tokenId) public {
        uint256 partnerId = _entangledPartners[tokenId];
        require(partnerId != 0, "QENT: Not entangled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender],
            "QENT: Caller is not owner/approved/operator"
        );

        _entangledPartners[tokenId] = 0;
        _entangledPartners[partnerId] = 0;

        // Apply a small state change or penalty upon un-entanglement
        QubitState storage state1 = _qubitStates[tokenId];
        QubitState storage state2 = _qubitStates[partnerId];

        state1.coherenceScore = state1.coherenceScore.div(2); // Coherence reduced
        state2.coherenceScore = state2.coherenceScore.div(2);
        state1.isInSuperposition = false; // Cannot be in superposition when not entangled
        state2.isInSuperposition = false;
        state1.lastStateChangeTime = block.timestamp;
        state2.lastStateChangeTime = block.timestamp;

        emit UnEntangled(tokenId, partnerId);
        emit StateChanged(tokenId, state1, state1); // Emit state change
        emit StateChanged(partnerId, state2, state2); // Emit state change
    }

    /**
     * @dev Attempts to entangle two previously un-entangled Qubits owned by the same address.
     * Requirements: Both tokens must exist, be un-entangled, owned by the same address, and caller must be owner/approved/operator for both.
     * Function 5: reEntanglePair
     */
    function reEntanglePair(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "QENT: Cannot entangle a token with itself");
        require(_exists(tokenId1) && _exists(tokenId2), "QENT: Tokens must exist");
        require(!isEntangled(tokenId1) && !isEntangled(tokenId2), "QENT: Tokens must not be entangled");
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        require(owner1 == owner2, "QENT: Tokens must be owned by the same address");
        require(
            _isApprovedOrOwner(msg.sender, tokenId1) && _isApprovedOrOwner(msg.sender, tokenId2) || _allowedOperators[msg.sender],
            "QENT: Caller is not owner/approved/operator for both"
        );

        _entangledPartners[tokenId1] = tokenId2;
        _entangledPartners[tokenId2] = tokenId1;

        // Re-initialize or adjust states upon re-entanglement
        QubitState storage state1 = _qubitStates[tokenId1];
        QubitState storage state2 = _qubitStates[tokenId2];

        // Example state adjustment: average energy, combine spins (simplified)
        uint256 avgEnergy = (state1.energyLevel + state2.energyLevel) / 2;
        state1.energyLevel = avgEnergy;
        state2.energyLevel = avgEnergy;
        state1.spin = uint8((state1.spin + state2.spin) % 2); // Simple spin interaction
        state2.spin = state1.spin; // Ensure spins are correlated/anti-correlated as part of entanglement

        // Coherence gets a small boost or reset
        state1.coherenceScore = state1.coherenceScore.add(100).min(1000); // Example cap at 1000
        state2.coherenceScore = state2.coherenceScore.add(100).min(1000);
        state1.lastStateChangeTime = block.timestamp;
        state2.lastStateChangeTime = block.timestamp;

        emit Entangled(tokenId1, tokenId2);
        emit StateChanged(tokenId1, state1, state1); // Emit state change
        emit StateChanged(tokenId2, state2, state2); // Emit state change
    }

    /**
     * @dev Burns one Qubit and its entangled partner. Requires ownership or operator status.
     * If not entangled, only burns the specified token.
     * Function 6: burnEntangledPair
     */
    function burnEntangledPair(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender],
            "QENT: Caller is not owner/approved/operator"
        );

        uint256 partnerId = _entangledPartners[tokenId];

        // Remove entanglement link first
        if (partnerId != 0) {
             _entangledPartners[tokenId] = 0;
            _entangledPartners[partnerId] = 0;
            emit UnEntangled(tokenId, partnerId); // Emit un-entangled before burn
        }

        // Burn the token and its partner if it existed
        _burn(tokenId);
        delete _qubitStates[tokenId];
        delete _lastCoherenceDecayCheck[tokenId];

        if (partnerId != 0) {
            require(_exists(partnerId), "QENT: Partner token must exist to be burned");
             // Check ownership explicitly before burning partner, unless caller is operator
             if (!_allowedOperators[msg.sender]) {
                require(_isApprovedOrOwner(msg.sender, partnerId), "QENT: Caller must own or be approved for partner to burn pair");
             }
            _burn(partnerId);
            delete _qubitStates[partnerId];
            delete _lastCoherenceDecayCheck[partnerId];
        }
    }


    // --- Qubit State Management & Operations ---

    /**
     * @dev Returns the current QubitState struct for a Qubit. Applies decay before returning.
     * Function 7: getQubitState
     */
    function getQubitState(uint256 tokenId) public view returns (QubitState memory) {
        require(_exists(tokenId), "QENT: Token does not exist");
        QubitState memory currentState = _qubitStates[tokenId];
        currentState.coherenceScore = _calculateDecayedCoherence(tokenId, currentState);
        return currentState;
    }

    /**
     * @dev Returns the QubitState for a Qubit and its entangled partner (if any). Applies decay.
     * Function 8: getPairState
     */
    function getPairState(uint256 tokenId) public view returns (QubitState memory selfState, QubitState memory partnerState) {
        selfState = getQubitState(tokenId); // Uses the decay calculation

        uint256 partnerId = _entangledPartners[tokenId];
        if (partnerId != 0) {
            partnerState = getQubitState(partnerId); // Uses the decay calculation
        } else {
            // Return a zero-initialized struct if no partner
            partnerState = QubitState(0, 0, 0, false, 0);
        }
        return (selfState, partnerState);
    }


    /**
     * @dev Puts a non-entangled Qubit into a superposition state. Requires ownership/approved/operator.
     * Function 9: superposeState
     */
    function superposeState(uint256 tokenId) public {
        require(_exists(tokenId), "QENT: Token does not exist");
        require(!isEntangled(tokenId), "QENT: Cannot superpose an entangled token");
        require(_isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender], "QENT: Caller is not owner/approved/operator");

        QubitState storage state = _qubitStates[tokenId];
        require(!state.isInSuperposition, "QENT: Token already in superposition");

        emit StateChanged(tokenId, state, state); // Emit BEFORE state change
        state.isInSuperposition = true;
        state.lastStateChangeTime = block.timestamp;
        emit StateChanged(tokenId, state, state); // Emit AFTER state change
    }

    /**
     * @dev Applies a simulated Hadamard gate. Affects the Qubit's spin/state and its entangled partner.
     * Requires ownership/approved/operator. Cannot be in superposition.
     * Function 10: applyHadamardGate
     */
    function applyHadamardGate(uint256 tokenId) public {
        require(_exists(tokenId), "QENT: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender], "QENT: Caller is not owner/approved/operator");

        QubitState storage state = _qubitStates[tokenId];
        require(!state.isInSuperposition, "QENT: Cannot apply gate to token in superposition");

        emit StateChanged(tokenId, state, state); // Emit BEFORE state change

        // Simulate Hadamard effect: Simple spin flip + energy change, affects partner
        state.spin = state.spin == 0 ? 1 : 0;
        state.energyLevel = state.energyLevel.add(50); // Energy cost/gain

        uint256 partnerId = _entangledPartners[tokenId];
        if (partnerId != 0) {
            QubitState storage partnerState = _qubitStates[partnerId];
            emit StateChanged(partnerId, partnerState, partnerState); // Emit BEFORE partner state change
            // Entanglement effect: Partner's spin flips too (or based on correlation)
            partnerState.spin = partnerState.spin == 0 ? 1 : 0;
            partnerState.energyLevel = partnerState.energyLevel.add(25); // Shared energy change
            partnerState.lastStateChangeTime = block.timestamp;
            emit StateChanged(partnerId, partnerState, partnerState); // Emit AFTER partner state change
        }

        state.lastStateChangeTime = block.timestamp;
        emit StateChanged(tokenId, state, state); // Emit AFTER state change
    }

    /**
     * @dev Applies a simulated Controlled-NOT gate between two *entangled* Qubits.
     * State change on target depends on control's spin. Requires ownership/approved/operator for both.
     * Cannot be in superposition.
     * Function 11: applyCnotGate
     */
    function applyCnotGate(uint256 controlTokenId, uint256 targetTokenId) public {
        require(controlTokenId != targetTokenId, "QENT: Control and target cannot be the same");
        require(_exists(controlTokenId) && _exists(targetTokenId), "QENT: Tokens must exist");
        require(isEntangled(controlTokenId) && _entangledPartners[controlTokenId] == targetTokenId, "QENT: Tokens must be entangled partners");
        require(
             (_isApprovedOrOwner(msg.sender, controlTokenId) && _isApprovedOrOwner(msg.sender, targetTokenId)) || _allowedOperators[msg.sender],
            "QENT: Caller is not owner/approved/operator for both"
        );

        QubitState storage controlState = _qubitStates[controlTokenId];
        QubitState storage targetState = _qubitStates[targetTokenId];

        require(!controlState.isInSuperposition && !targetState.isInSuperposition, "QENT: Cannot apply gate to tokens in superposition");

        emit StateChanged(controlTokenId, controlState, controlState); // Emit BEFORE
        emit StateChanged(targetTokenId, targetState, targetState); // Emit BEFORE

        // Simulate CNOT: If control spin is 1, flip target spin.
        if (controlState.spin == 1) {
            targetState.spin = targetState.spin == 0 ? 1 : 0;
        }

        // CNOT changes energy levels for both
        controlState.energyLevel = controlState.energyLevel.add(30);
        targetState.energyLevel = targetState.energyLevel.add(30);

        controlState.lastStateChangeTime = block.timestamp;
        targetState.lastStateChangeTime = block.timestamp;

        emit StateChanged(controlTokenId, controlState, controlState); // Emit AFTER
        emit StateChanged(targetTokenId, targetState, targetState); // Emit AFTER
    }

     /**
     * @dev Swaps the full QubitState between two *entangled* Qubits.
     * Requires ownership/approved/operator for both. Cannot be in superposition.
     * Function 12: swapStates
     */
    function swapStates(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "QENT: Cannot swap states with itself");
        require(_exists(tokenId1) && _exists(tokenId2), "QENT: Tokens must exist");
        require(isEntangled(tokenId1) && _entangledPartners[tokenId1] == tokenId2, "QENT: Tokens must be entangled partners");
         require(
             (_isApprovedOrOwner(msg.sender, tokenId1) && _isApprovedOrOwner(msg.sender, tokenId2)) || _allowedOperators[msg.sender],
            "QENT: Caller is not owner/approved/operator for both"
        );

        QubitState storage state1 = _qubitStates[tokenId1];
        QubitState storage state2 = _qubitStates[tokenId2];

        require(!state1.isInSuperposition && !state2.isInSuperposition, "QENT: Cannot swap states of tokens in superposition");

        emit StateChanged(tokenId1, state1, state1); // Emit BEFORE
        emit StateChanged(tokenId2, state2, state2); // Emit BEFORE

        // Perform the swap
        QubitState memory tempState = state1;
        _qubitStates[tokenId1] = state2;
        _qubitStates[tokenId2] = tempState;

        // Update timestamps after swap
        _qubitStates[tokenId1].lastStateChangeTime = block.timestamp;
        _qubitStates[tokenId2].lastStateChangeTime = block.timestamp;

        emit StateChanged(tokenId1, state2, tempState); // Emit AFTER (state1 is now state2)
        emit StateChanged(tokenId2, tempState, state2); // Emit AFTER (state2 is now state1)
    }

    /**
     * @dev Simulates measuring one Qubit in an entangled pair.
     * Collapses superposition (if any) and pseudo-randomly updates both Qubits' states based on entanglement.
     * Requires ownership/approved/operator.
     * Function 13: measureEntangledState
     */
    function measureEntangledState(uint256 tokenId) public {
         require(_exists(tokenId), "QENT: Token does not exist");
         require(_isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender], "QENT: Caller is not owner/approved/operator");

        uint256 partnerId = _entangledPartners[tokenId];
        require(partnerId != 0, "QENT: Token is not entangled, measure individually (not implemented)"); // For this contract, measurement requires entanglement

        QubitState storage state1 = _qubitStates[tokenId];
        QubitState storage state2 = _qubitStates[partnerId];

        emit StateChanged(tokenId, state1, state1); // Emit BEFORE
        emit StateChanged(partnerId, state2, state2); // Emit BEFORE
        emit Measured(tokenId, partnerId);

        // --- Simplified Pseudo-Random State Collapse and Entangled Effect ---
        // WARNING: Using block.timestamp and block.difficulty (prevrandao) is NOT
        // cryptographically secure randomness on most blockchains and can be manipulated
        // by miners/validators. For real-world use, integrate with a VRF (e.g., Chainlink VRF).

        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // On PoS, this is prevrandao
            msg.sender,
            tokenId,
            partnerId,
            tx.gasprice // Additional weak entropy
        )));

        // Determine the "measured" spin based on entropy
        // If in superposition, the measurement determines the outcome
        // If not in superposition, the "measurement" might still cause state jiggle

        bool collapseToZero = entropy % 2 == 0;

        // Collapse superposition if applicable
        state1.isInSuperposition = false;
        state2.isInSuperposition = false; // Entangled state collapse

        // Update spins based on measurement outcome and entanglement
        // Example: The measurement outcome dictates state1's spin, and state2's spin
        // is then determined by the *type* of entanglement (e.g., always anti-correlated, always correlated)
        // We'll use a simple rule: Measured token gets collapseToZero spin, partner gets opposite spin.
        state1.spin = collapseToZero ? 0 : 1;
        state2.spin = collapseToZero ? 1 : 0; // Simple anti-correlation example

        // Measurement can also affect energy and coherence
        state1.energyLevel = state1.energyLevel.add(entropy % 100).min(500); // Add some jitter
        state2.energyLevel = state2.energyLevel.add(entropy % 100).min(500);
        state1.coherenceScore = state1.coherenceScore.add(entropy % 50).min(1000); // Measurement can sometimes boost coherence
        state2.coherenceScore = state2.coherenceScore.add(entropy % 50).min(1000);


        state1.lastStateChangeTime = block.timestamp;
        state2.lastStateChangeTime = block.timestamp;
        _lastCoherenceDecayCheck[tokenId] = block.timestamp; // Reset decay timer on measurement
        _lastCoherenceDecayCheck[partnerId] = block.timestamp; // Reset decay timer on measurement

        emit StateChanged(tokenId, state1, state1); // Emit AFTER
        emit StateChanged(partnerId, state2, state2); // Emit AFTER
    }

    /**
     * @dev Performs `measureEntangledState` on multiple token IDs.
     * Requires ownership/approved/operator for *all* entangled pairs involved.
     * Function 14: bulkMeasure
     */
    function bulkMeasure(uint256[] calldata tokenIds) public {
        // Basic check for operator or owner/approved for *all* relevant tokens
        if (!_allowedOperators[msg.sender]) {
             for (uint i = 0; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];
                require(_exists(tokenId), "QENT: Token in list does not exist");
                require(_isApprovedOrOwner(msg.sender, tokenId), "QENT: Caller must own or be approved for all tokens in list");
                // If entangled, also check the partner owner/approval implicitly via the requirement in measureEntangledState
             }
        }

        // Iterate and measure each token
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
             // Avoid measuring the same pair twice if both tokenIds are in the list
            if (_entangledPartners[tokenId] == 0 || tokenId < _entangledPartners[tokenId]) {
                 // Only process the pair once via the lower tokenId or if not entangled
                measureEntangledState(tokenId);
            }
        }
    }


    // --- Coherence Mechanics ---

    /**
     * @dev Internal function to calculate decayed coherence score.
     */
    function _calculateDecayedCoherence(uint256 tokenId, QubitState memory state) internal view returns (uint256) {
        uint256 lastCheckTime = _lastCoherenceDecayCheck[tokenId];
        uint256 timeElapsed = block.timestamp - lastCheckTime;
        uint256 decayAmount = timeElapsed.mul(coherenceDecayRatePerSecond);
        return state.coherenceScore > decayAmount ? state.coherenceScore - decayAmount : 0;
    }

     /**
     * @dev Returns the calculated current coherence score (decay applied).
     * Function 15: getCoherenceScore
     */
    function getCoherenceScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENT: Token does not exist");
        return _calculateDecayedCoherence(tokenId, _qubitStates[tokenId]);
    }

    /**
     * @dev Resets coherence score to 0 after decay and potentially credits owner with yield.
     * Requires ownership/approved/operator. Applies pending decay before harvesting.
     * Function 16: harvestCoherence
     */
    function harvestCoherence(uint256 tokenId) public {
        require(_exists(tokenId), "QENT: Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender], "QENT: Caller is not owner/approved/operator");

        QubitState storage state = _qubitStates[tokenId];
        uint256 currentDecayedCoherence = _calculateDecayedCoherence(tokenId, state);

        // Calculate yield (example: based on harvested coherence and a factor)
        uint256 yieldAmount = currentDecayedCoherence.mul(harvestYieldFactor);

        // Reset coherence score *after* calculating yield
        state.coherenceScore = 0;
        _lastCoherenceDecayCheck[tokenId] = block.timestamp; // Reset decay timer

        // --- Placeholder for Yield Distribution ---
        // In a real contract, this would involve transferring an ERC20 token,
        // updating an internal balance, or similar.
        // For this example, we just emit an event.
        // Example: IYieldToken yieldToken = IYieldToken(addressOfYieldToken);
        // yieldToken.mint(ownerOf(tokenId), yieldAmount);
        // Or: _internalYieldBalances[ownerOf(tokenId)] += yieldAmount;
        // This requires additional state and functions for the yield token or balance.
        // We will just emit the event.

        emit CoherenceHarvested(tokenId, currentDecayedCoherence, yieldAmount);
        emit StateChanged(tokenId, state, state); // Emit state change (coherence reset)
    }

    /**
     * @dev Callable by anyone or allowed operator; triggers coherence decay check if due.
     * This allows external keepers to maintain coherence state without requiring owner action.
     * Function 17: decayCoherence
     */
    function decayCoherence(uint256 tokenId) public {
        require(_exists(tokenId), "QENT: Token does not exist");
        // Allow anyone OR operator to trigger decay
        require(msg.sender == tx.origin || _allowedOperators[msg.sender], "QENT: Caller is not origin or allowed operator"); // Prevent contract-based triggers unless operator

        QubitState storage state = _qubitStates[tokenId];
        uint256 oldCoherence = state.coherenceScore;
        uint256 newCoherence = _calculateDecayedCoherence(tokenId, state);

        if (newCoherence < oldCoherence) {
            state.coherenceScore = newCoherence;
            _lastCoherenceDecayCheck[tokenId] = block.timestamp; // Update check time
            emit CoherenceDecayed(tokenId, oldCoherence, newCoherence);
            emit StateChanged(tokenId, state, state); // Emit state change (coherence decay)
        }
    }

     /**
     * @dev Allows owner/approved/operator to increase a Qubit's coherence score.
     * Function 18: boostCoherence
     */
    function boostCoherence(uint256 tokenId, uint256 amount) public {
         require(_exists(tokenId), "QENT: Token does not exist");
         require(_isApprovedOrOwner(msg.sender, tokenId) || _allowedOperators[msg.sender], "QENT: Caller is not owner/approved/operator");
         require(amount > 0, "QENT: Amount must be positive");

         // Optional: Require payment or token burn to boost coherence
         // require(msg.value >= requiredEth, "QENT: Insufficient ETH");
         // IERC20 token = IERC20(address(tokenAddress));
         // token.transferFrom(msg.sender, address(this), requiredTokens);

        QubitState storage state = _qubitStates[tokenId];
        uint256 oldCoherence = getCoherenceScore(tokenId); // Get decayed score first
        state.coherenceScore = oldCoherence.add(amount).min(1000); // Boost and apply cap (example cap 1000)
        _lastCoherenceDecayCheck[tokenId] = block.timestamp; // Reset decay timer after boost

        emit StateChanged(tokenId, state, state); // Emit state change (coherence boost)
    }


    // --- Access Control & Utilities ---

    /**
     * @dev Sets the base URI for token metadata. Only callable by the owner.
     * Function 19: setBaseURI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * @dev Grants or revokes the 'Operator' role for specific maintenance functions.
     * Only callable by the owner.
     * Function 20: setAllowedOperator
     */
    function setAllowedOperator(address operator, bool approved) public onlyOwner {
        _allowedOperators[operator] = approved;
        emit OperatorAllowed(operator, approved);
    }

    /**
     * @dev Checks if an address has the 'Operator' role.
     * Function 21: isAllowedOperator
     */
    function isAllowedOperator(address operator) public view returns (bool) {
        return _allowedOperators[operator];
    }

     /**
     * @dev Sets the rate at which coherence decays per second. Only callable by owner.
     * Function 22: setDecayRate
     */
    function setDecayRate(uint256 ratePerSecond) public onlyOwner {
        coherenceDecayRatePerSecond = ratePerSecond;
    }

    /**
     * @dev Sets the factor used to calculate yield from harvesting coherence. Only callable by owner.
     * Function 23: setHarvestYieldFactor
     */
    function setHarvestYieldFactor(uint256 factor) public onlyOwner {
        harvestYieldFactor = factor;
    }

    // --- Internal Helpers ---

    /**
     * @dev Checks if the caller is the owner of the token or is approved/operator.
     */
    function _isApprovedOrOwner(address caller, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return caller == tokenOwner || getApproved(tokenId) == caller || isApprovedForAll(tokenOwner, caller);
    }
}
```

**Explanation of Advanced Concepts & Creativity:**

1.  **Quantum Entanglement Analogy:** The core mechanic of linking NFTs so that operations on one affect the other (`applyHadamardGate`, `applyCnotGate`, `measureEntangledState`) is a direct analogy. This creates complex, interdependent digital assets. The restriction on transferring single entangled tokens reinforces this bond.
2.  **Dynamic State & Metadata:** The `QubitState` struct introduces internal state variables that go beyond typical static NFT attributes. `tokenURI` dynamically generates metadata reflecting this state, making the NFTs "alive" on-chain.
3.  **Quantum Operations:** Functions like `applyHadamardGate` and `applyCnotGate` simulate quantum logic gates. While simplified, they provide a unique interaction mechanism for the NFTs, changing their state based on specific rules and their entangled partners.
4.  **Measurement & State Collapse:** `measureEntangledState` simulates collapsing a superposition (though the contract currently only allows superposition for non-entangled tokens for simplicity, this could be extended) and forces a pseudo-random state outcome for *both* entangled Qubits based on shared entropy.
5.  **Coherence & Decay/Harvest:** The `coherenceScore` introduces a time-sensitive, yield-bearing element. It decays, requiring maintenance (`decayCoherence` callable by anyone/operator) or strategic harvesting (`harvestCoherence`). This adds a resource-management layer to the NFTs.
6.  **Role-Based Operators:** The `_allowedOperators` mapping provides a granular access control mechanism beyond the standard ERC721 owner/approved roles, allowing specific addresses (like bots or other contracts) to perform limited, defined actions (like triggering decay) without full control.
7.  **Complex Transfer Logic:** Overriding `_beforeTokenTransfer` to disallow transferring entangled tokens individually requires users to actively manage the entanglement state (`unEntanglePair`) before trading, adding friction and strategic depth.
8.  **Bulk Operations:** `bulkMeasure` shows how operations can be designed to handle multiple assets efficiently, relevant for applications managing many Qubits.

This contract provides a foundation for a unique game, art project, or experimental digital asset ecosystem where the relationships and dynamic properties of the NFTs are central to their value and interaction model. Remember that the pseudo-randomness used is for demonstration; a production system requiring unpredictable outcomes should integrate with a secure VRF.