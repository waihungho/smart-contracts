Okay, let's create a smart contract that simulates a unique concept: "Quantum Entangled Tokens". This isn't a standard ERC-anything. Instead, individual tokens can be paired up into "entangled states". Actions performed on one token within an entangled pair probabilistically or deterministically affect the other, much like quantum entanglement collapses states upon measurement. It will also incorporate concepts like potential energy accumulation in entangled pairs that can be released upon measurement.

This contract will explore:
*   Non-standard token ownership/management.
*   Simulated probabilistic outcomes and state manipulation.
*   Interdependent token states (entanglement).
*   Value dynamics based on state and entanglement.
*   A relatively high number of functions to manage these unique mechanics.

**Disclaimer:** True quantum mechanics cannot be replicated on a classical blockchain like Ethereum. This contract uses the *concept* of entanglement and superposition as a creative framework for complex state transitions and token interactions. The "randomness" relies on block data, which is predictable and should NOT be used for high-security applications.

---

**Outline and Function Summary: QuantumEntangledToken**

**Concept:**
A novel token where individual tokens can be linked into "entangled pairs". Actions on one token in a pair influence its partner's state. Entangled pairs can accumulate "potential energy" (value) that is released upon "measurement" (state collapse). Unentangled tokens can exist in a simulated "superposition" with probabilistic states.

**State Variables:**
*   `_nextTokenId`: Counter for issuing unique token IDs.
*   `_owners`: Maps token ID to its owner address.
*   `_tokenStates`: Maps token ID to its `SpinState` (Uninitialized, SpinUp, SpinDown).
*   `_entangledPartners`: Maps token ID to its entangled partner's ID.
*   `_isEntangled`: Maps token ID to a boolean indicating if it's currently entangled.
*   `_pairPotentialEnergy`: Maps a pair identifier (e.g., the lower token ID in the pair) to accumulated Ether value.
*   `_lastDecayBlock`: Block number when potential energy decay was last applied.
*   `_decayRatePerBlock`: Percentage representing how much potential energy decays per block.
*   `_measurementFee`: Ether required to perform a state measurement.

**Enums:**
*   `SpinState`: Represents the possible states of a token (Uninitialized, SpinUp, SpinDown).

**Events:**
*   `PairMinted`: Emitted when a new entangled pair is created.
*   `PairTransferred`: Emitted when an entangled pair is transferred.
*   `TokensEntangled`: Emitted when two existing tokens are entangled.
*   `PairDisentangled`: Emitted when an entangled pair is broken.
*   `StateMeasured`: Emitted when an entangled token's state is measured, affecting its partner.
*   `SuperpositionAttempted`: Emitted when an unentangled token's state is set probabilistically.
*   `FluctuationApplied`: Emitted when an unentangled token's state potentially flips probabilistically.
*   `SpinsAligned`: Emitted when two unentangled tokens' states are aligned.
*   `StateFlipped`: Emitted when an unentangled token's state is directly flipped.
*   `ValueCollapsed`: Emitted when potential energy is released from an entangled pair.
*   `PotentialBoosted`: Emitted when potential energy is added to an entangled pair.
*   `DecayApplied`: Emitted when potential energy decay is processed.
*   `StateSynchronized`: Emitted when a state synchronization operation is performed.
*   `OwnershipTransferred`: Standard event if Ownable is used (not used here, using custom checks).

**Functions (24 Total):**

1.  `mintEntangledPair()`: Creates two new tokens, sets their initial states, and immediately entangles them. Caller becomes the owner of the pair.
2.  `transferEntangledPair(uint256 _tokenId, address _to)`: Transfers an *entangled* pair (identified by one token ID) to a new address. Both tokens in the pair are transferred.
3.  `entangleTokens(uint256 _tokenIdA, uint256 _tokenIdB)`: Attempts to entangle two *unentangled* tokens. Requires the caller to own both tokens.
4.  `disentanglePair(uint256 _tokenId)`: Breaks the entanglement of a pair containing `_tokenId`. Requires the caller to own the pair. Potential energy is burned unless collapsed first.
5.  `measureTokenState(uint256 _tokenId)`: Simulates measuring the state of an *entangled* token. Requires a fee (`_measurementFee`). Deterministically sets the state of `_tokenId` based on a pseudo-random outcome and sets its partner's state to the opposite. Triggers potential energy collapse.
6.  `attemptSuperposition(uint256 _tokenId)`: Simulates placing an *unentangled* token into a superposition state. Randomly sets its state to SpinUp or SpinDown. Requires the caller to own the token.
7.  `applyQuantumFluctuation(uint256 _tokenId)`: Applies a probabilistic state flip to an *unentangled* token. Based on pseudo-randomness, the token's state might flip. Requires the caller to own the token.
8.  `alignSpins(uint256 _tokenIdA, uint256 _tokenIdB, SpinState _targetState)`: Attempts to set two *unentangled* tokens (owned by the caller) to a specific target state.
9.  `flipState(uint256 _tokenId)`: Directly flips the state of an *unentangled* token (SpinUp to SpinDown, or vice versa). Requires the caller to own the token.
10. `collapseEntangledValue(uint256 _tokenId)`: Explicitly triggers the transfer of potential energy from an *entangled* pair (identified by `_tokenId`) to its owner. Can only be called *after* a measurement has occurred (or as part of `measureTokenState`). Requires the caller to own the pair.
11. `boostPotentialEnergy(uint256 _tokenId) payable`: Allows the owner of an *entangled* pair to send Ether (`msg.value`) to the contract, increasing the pair's potential energy.
12. `decayPotentialEnergy()`: Public function that can be called by anyone to trigger potential energy decay for *all* pairs based on elapsed blocks. Helps maintain the simulation state. Has a block threshold to prevent spamming.
13. `synchronizeStateWithPartner(uint256 _tokenId)`: A function for an entangled token. In a real system, this might refresh a local state copy. Here, it serves as a specific interaction type for entangled tokens, maybe adding a minor potential energy boost or costing gas as a "check". Let's add a minor boost. Requires caller owns the token.
14. `setMeasurementFee(uint256 _fee)`: Sets the fee required for `measureTokenState`. (Consider this as a simplified admin function).
15. `setDecayRate(uint256 _rate)`: Sets the percentage decay rate for potential energy. (Simplified admin function).
16. `getTokenState(uint256 _tokenId) view`: Returns the current `SpinState` of a token.
17. `getEntangledPartner(uint256 _tokenId) view`: Returns the token ID of the entangled partner, or 0 if not entangled.
18. `isEntangled(uint256 _tokenId) view`: Returns true if the token is currently entangled.
19. `getOwnerOfToken(uint256 _tokenId) view`: Returns the owner address of a specific token.
20. `getOwnerOfPair(uint256 _tokenId) view`: Returns the owner address of the pair containing `_tokenId` (requires it to be entangled).
21. `getPotentialEnergyOfPair(uint256 _tokenId) view`: Returns the current potential energy (Ether) held for the pair containing `_tokenId`.
22. `getTotalSupply() view`: Returns the total number of individual tokens minted.
23. `getEntangledPairCount() view`: Returns the total number of active entangled pairs.
24. `getUnentangledTokenCount() view`: Returns the total number of tokens not currently entangled.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledToken
 * @dev A novel smart contract simulating quantum entanglement concepts with tokens.
 * Tokens can be linked into entangled pairs where actions on one affect the other.
 * Entangled pairs can accumulate potential energy (Ether) released upon state measurement.
 * Unentangled tokens exhibit probabilistic state behaviors.
 *
 * This is a conceptual exploration and does not replicate true quantum mechanics.
 * Randomness relies on block data which is predictable and not suitable for security-sensitive applications.
 *
 * Outline:
 * 1. Contract Setup: State variables, Enums, Events.
 * 2. Core Token Operations: Minting pairs, Transferring pairs.
 * 3. Entanglement Management: Entangling and Disentangling tokens/pairs.
 * 4. State Manipulation: Measuring entangled states, probabilistic superposition/fluctuation for unentangled tokens, direct state flips, aligning spins.
 * 5. Value Dynamics: Boosting and Collapsing potential energy, Decay mechanism, State synchronization effects.
 * 6. Utility & Information: Getters for state, ownership, entanglement status, counts, etc.
 * 7. Simplified Admin: Functions to set parameters (fee, decay).
 *
 * Function Summary:
 * 1. mintEntangledPair() - Creates a new entangled token pair.
 * 2. transferEntangledPair(uint256 _tokenId, address _to) - Transfers an entangled pair.
 * 3. entangleTokens(uint256 _tokenIdA, uint256 _tokenIdB) - Entangles two unentangled tokens.
 * 4. disentanglePair(uint256 _tokenId) - Breaks the entanglement of a pair.
 * 5. measureTokenState(uint256 _tokenId) - Measures an entangled token's state, collapsing partner's state and potentially value. Requires fee.
 * 6. attemptSuperposition(uint256 _tokenId) - Sets an unentangled token's state probabilistically.
 * 7. applyQuantumFluctuation(uint256 _tokenId) - Probabilistically flips an unentangled token's state.
 * 8. alignSpins(uint256 _tokenIdA, uint256 _tokenIdB, SpinState _targetState) - Sets two unentangled tokens to a target state.
 * 9. flipState(uint256 _tokenId) - Directly flips an unentangled token's state.
 * 10. collapseEntangledValue(uint256 _tokenId) - Explicitly releases potential energy from an entangled pair.
 * 11. boostPotentialEnergy(uint256 _tokenId) payable - Adds Ether to a pair's potential energy.
 * 12. decayPotentialEnergy() - Triggers potential energy decay for all pairs based on time (blocks).
 * 13. synchronizeStateWithPartner(uint256 _tokenId) - Interaction for entangled tokens, adds minor potential energy.
 * 14. setMeasurementFee(uint256 _fee) - Sets the fee for measurement. (Admin-like)
 * 15. setDecayRate(uint256 _rate) - Sets the potential energy decay rate. (Admin-like)
 * 16. getTokenState(uint256 _tokenId) view - Get state.
 * 17. getEntangledPartner(uint256 _tokenId) view - Get partner ID.
 * 18. isEntangled(uint256 _tokenId) view - Check entanglement status.
 * 19. getOwnerOfToken(uint256 _tokenId) view - Get token owner.
 * 20. getOwnerOfPair(uint256 _tokenId) view - Get pair owner (if entangled).
 * 21. getPotentialEnergyOfPair(uint256 _tokenId) view - Get pair potential energy.
 * 22. getTotalSupply() view - Get total individual tokens.
 * 23. getEntangledPairCount() view - Get total entangled pairs.
 * 24. getUnentangledTokenCount() view - Get total unentangled tokens.
 */
contract QuantumEntangledToken {

    enum SpinState { Uninitialized, SpinUp, SpinDown }

    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => SpinState) private _tokenStates;
    mapping(uint256 => uint256) private _entangledPartners; // Maps token ID to its partner ID
    mapping(uint256 => bool) private _isEntangled; // Maps token ID to entanglement status
    mapping(uint256 => uint256) private _pairPotentialEnergy; // Maps the *lower* token ID of a pair to energy (in Wei)
    uint256 private _lastDecayBlock;
    uint256 private _decayRatePerBlock = 1; // 1 = 0.1%, 10 = 1%, 100 = 10% decay per block difference
    uint256 private _measurementFee = 0 ether; // Fee required for measurement

    // For listing owned tokens/pairs (Gas intensive for large numbers!)
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex; // To quickly remove tokens from list

    // --- Events ---
    event PairMinted(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed owner);
    event PairTransferred(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed from, address indexed to);
    event TokensEntangled(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed owner);
    event PairDisentangled(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed owner, uint256 remainingPotentialEnergy);
    event StateMeasured(uint256 indexed tokenId, SpinState newState, uint256 indexed partnerTokenId, SpinState partnerNewState, uint256 potentialEnergyReleased);
    event SuperpositionAttempted(uint256 indexed tokenId, SpinState newState);
    event FluctuationApplied(uint256 indexed tokenId, SpinState newState);
    event SpinsAligned(uint256 indexed tokenIdA, uint256 indexed tokenIdB, SpinState targetState, address indexed owner);
    event StateFlipped(uint256 indexed tokenId, SpinState newState);
    event ValueCollapsed(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 amount, address indexed owner);
    event PotentialBoosted(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 amount, uint256 newTotal);
    event DecayApplied(uint256 blocksProcessed, uint256 totalEnergyDecayed);
    event StateSynchronized(uint256 indexed tokenId, uint256 indexed partnerTokenId, uint256 minorPotentialBoost);

    // --- Modifiers (Inline checks used instead for function count) ---

    // --- Constructor ---
    constructor() {
        _nextTokenId = 1; // Start token IDs from 1
        _lastDecayBlock = block.number;
    }

    // --- Internal Helpers ---
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    function _isPair(uint256 _tokenIdA, uint256 _tokenIdB) internal view returns (bool) {
         return _exists(_tokenIdA) && _exists(_tokenIdB) && _isEntangled[_tokenIdA] && _entangledPartners[_tokenIdA] == _tokenIdB && _entangledPartners[_tokenIdB] == _tokenIdA;
    }

    function _getPairId(uint256 _tokenId) internal view returns (uint256) {
        if (!_isEntangled[_tokenId]) return 0;
        uint256 partnerId = _entangledPartners[_tokenId];
        return _tokenId < partnerId ? _tokenId : partnerId;
    }

    function _transferOwnership(address _from, address _to, uint256 _tokenId) internal {
        require(_owners[_tokenId] == _from, "QET: Transfer not authorized");
        _owners[_tokenId] = _to;

        // Update owned tokens list (inefficient for large numbers)
        // Find and remove from _from's list
        uint256 lastIndex = _ownedTokens[_from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[_tokenId];
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _ownedTokens[_from][lastIndex];
            _ownedTokens[_from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[_from].pop();
        delete _ownedTokensIndex[_tokenId];

        // Add to _to's list
        _ownedTokens[_to].push(_tokenId);
        _ownedTokensIndex[_tokenId] = _ownedTokens[_to].length - 1;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "QET: Mint to zero address");
        require(!_exists(_tokenId), "QET: Token already exists");
        _owners[_tokenId] = _to;
        _tokenStates[_tokenId] = SpinState.Uninitialized; // Default initial state

        // Add to owned tokens list
        _ownedTokens[_to].push(_tokenId);
        _ownedTokensIndex[_tokenId] = _ownedTokens[_to].length - 1;
    }

    function _applyDecay() internal {
        uint256 currentBlock = block.number;
        if (currentBlock <= _lastDecayBlock) {
            // Decay already applied for this block or no blocks passed
            return;
        }

        uint256 blocksProcessed = currentBlock - _lastDecayBlock;
        uint256 totalEnergyDecayed = 0;

        // NOTE: Iterating through all pairs is highly inefficient and gas-prohibitive
        // for a large number of pairs in production. This is for illustrative purposes.
        // A real implementation might require off-chain handling or a different decay model.
        // For this example, we iterate through potential pair IDs (odd numbers up to _nextTokenId).
        // This is still inefficient but avoids tracking pairs explicitly in an array.
        for (uint256 pairId = 1; pairId < _nextTokenId; pairId += 2) {
             if (_isEntangled[pairId]) { // Check if this token is the lower half of an active pair
                uint256 energy = _pairPotentialEnergy[pairId];
                if (energy > 0) {
                    uint256 decayAmount = (energy * _decayRatePerBlock * blocksProcessed) / 1000; // decayRate is per mille (0.1%)
                    if (decayAmount > energy) decayAmount = energy;
                    _pairPotentialEnergy[pairId] -= decayAmount;
                    totalEnergyDecayed += decayAmount;
                 }
             }
        }

        _lastDecayBlock = currentBlock;
        emit DecayApplied(blocksProcessed, totalEnergyDecayed);
    }


    // --- Core Token Operations ---

    /**
     * @dev Mints a new entangled pair of tokens.
     * @return The IDs of the two minted tokens.
     */
    function mintEntangledPair() public returns (uint256 tokenIdA, uint256 tokenIdB) {
        _applyDecay(); // Apply decay before minting

        tokenIdA = _nextTokenId++;
        tokenIdB = _nextTokenId++;

        _mint(msg.sender, tokenIdA);
        _mint(msg.sender, tokenIdB);

        // Set entanglement
        _entangledPartners[tokenIdA] = tokenIdB;
        _entangledPartners[tokenIdB] = tokenIdA;
        _isEntangled[tokenIdA] = true;
        _isEntangled[tokenIdB] = true;

        // Initial state (can be random or fixed)
        // Using weak randomness from block data
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenIdA, tokenIdB)));
        if (rand % 2 == 0) {
             _tokenStates[tokenIdA] = SpinState.SpinUp;
             _tokenStates[tokenIdB] = SpinState.SpinDown;
        } else {
             _tokenStates[tokenIdA] = SpinState.SpinDown;
             _tokenStates[tokenIdB] = SpinState.SpinUp;
        }

        // Initialize potential energy for the pair
        uint256 pairId = tokenIdA < tokenIdB ? tokenIdA : tokenIdB;
        _pairPotentialEnergy[pairId] = 0; // Starts with 0 potential energy

        emit PairMinted(tokenIdA, tokenIdB, msg.sender);
    }

    /**
     * @dev Transfers an entangled pair to a new address.
     * Both tokens in the pair must be owned by the caller.
     * @param _tokenId A token ID belonging to the pair to transfer.
     * @param _to The recipient address.
     */
    function transferEntangledPair(uint256 _tokenId, address _to) public {
        _applyDecay(); // Apply decay before transfer

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");
        require(_to != address(0), "QET: Transfer to zero address");
        require(_to != msg.sender, "QET: Cannot transfer to self");

        uint256 partnerTokenId = _entangledPartners[_tokenId];
        require(_owners[partnerTokenId] == msg.sender, "QET: Caller does not own the partner token"); // Ensure caller owns both

        _transferOwnership(msg.sender, _to, _tokenId);
        _transferOwnership(msg.sender, _to, partnerTokenId);

        emit PairTransferred(_tokenId, partnerTokenId, msg.sender, _to);
    }

    // --- Entanglement Management ---

    /**
     * @dev Entangles two unentangled tokens.
     * Requires the caller to own both tokens.
     * @param _tokenIdA The ID of the first token.
     * @param _tokenIdB The ID of the second token.
     */
    function entangleTokens(uint256 _tokenIdA, uint256 _tokenIdB) public {
        _applyDecay(); // Apply decay before entangling

        require(_exists(_tokenIdA) && _exists(_tokenIdB), "QET: One or both tokens do not exist");
        require(_tokenIdA != _tokenIdB, "QET: Cannot entangle a token with itself");
        require(_owners[_tokenIdA] == msg.sender, "QET: Caller does not own token A");
        require(_owners[_tokenIdB] == msg.sender, "QET: Caller does not own token B");
        require(!_isEntangled[_tokenIdA] && !_isEntangled[_tokenIdB], "QET: One or both tokens are already entangled");

        _entangledPartners[_tokenIdA] = _tokenIdB;
        _entangledPartners[_tokenIdB] = _tokenIdA;
        _isEntangled[_tokenIdA] = true;
        _isEntangled[_tokenIdB] = true;

        // Reset states upon entanglement (simulate superposition collapse)
        _tokenStates[_tokenIdA] = SpinState.Uninitialized;
        _tokenStates[_tokenIdB] = SpinState.Uninitialized;

        // Initialize potential energy for the new pair
        uint256 pairId = _tokenIdA < _tokenIdB ? _tokenIdA : _tokenIdB;
        _pairPotentialEnergy[pairId] = 0;

        emit TokensEntangled(_tokenIdA, _tokenIdB, msg.sender);
    }

    /**
     * @dev Breaks the entanglement of a pair.
     * Requires the caller to own the pair.
     * Potential energy stored in the pair is lost unless collapsed first.
     * @param _tokenId A token ID belonging to the pair to disentangle.
     */
    function disentanglePair(uint256 _tokenId) public {
         _applyDecay(); // Apply decay before disentangling

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");

        uint256 partnerTokenId = _entangledPartners[_tokenId];
        require(_owners[partnerTokenId] == msg.sender, "QET: Caller does not own the partner token"); // Ensure caller owns both

        uint256 pairId = _getPairId(_tokenId);
        uint256 remainingEnergy = _pairPotentialEnergy[pairId];

        // Clear entanglement
        delete _entangledPartners[_tokenId];
        delete _entangledPartners[partnerTokenId];
        _isEntangled[_tokenId] = false;
        _isEntangled[partnerTokenId] = false;

        // Burn potential energy
        delete _pairPotentialEnergy[pairId];

        // Reset states
        _tokenStates[_tokenId] = SpinState.Uninitialized;
        _tokenStates[partnerTokenId] = SpinState.Uninitialized;

        emit PairDisentangled(_tokenId, partnerTokenId, msg.sender, remainingEnergy);
    }


    // --- State Manipulation ---

    /**
     * @dev Simulates measuring the state of an entangled token.
     * This collapses the state of this token and its partner to opposite values.
     * Releases any accumulated potential energy for the pair to the owner.
     * Requires the caller to own the pair and pay a fee.
     * @param _tokenId The ID of the entangled token to measure.
     */
    function measureTokenState(uint256 _tokenId) public payable {
        _applyDecay(); // Apply decay before measurement

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");
        require(msg.value >= _measurementFee, "QET: Insufficient measurement fee");

        // Refund excess if any
        if (msg.value > _measurementFee) {
            payable(msg.sender).transfer(msg.value - _measurementFee);
        }

        uint256 partnerTokenId = _entangledPartners[_tokenId];
        require(_owners[partnerTokenId] == msg.sender, "QET: Caller does not own partner token"); // Ensure caller owns pair

        // Use block data for pseudo-randomness (INSECURE for production)
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenId)));

        SpinState newState;
        SpinState partnerNewState;

        if (rand % 2 == 0) {
            newState = SpinState.SpinUp;
            partnerNewState = SpinState.SpinDown;
        } else {
            newState = SpinState.SpinDown;
            partnerNewState = SpinState.SpinUp;
        }

        _tokenStates[_tokenId] = newState;
        _tokenStates[partnerTokenId] = partnerNewState;

        // Collapse and transfer potential energy
        uint256 pairId = _getPairId(_tokenId);
        uint256 energyToTransfer = _pairPotentialEnergy[pairId];
        if (energyToTransfer > 0) {
            _pairPotentialEnergy[pairId] = 0;
            // Transfer Ether from contract balance (requires contract to have received it)
            if (address(this).balance >= energyToTransfer) {
                payable(msg.sender).transfer(energyToTransfer);
            } else {
                 // Log or handle insufficient contract balance
                 energyToTransfer = 0; // Indicate nothing was transferred if balance is low
            }
        }

        emit StateMeasured(_tokenId, newState, partnerTokenId, partnerNewState, energyToTransfer);
        emit ValueCollapsed(_tokenId, partnerTokenId, energyToTransfer, msg.sender);
    }

    /**
     * @dev Simulates placing an unentangled token into a superposition state.
     * Randomly sets its state to SpinUp or SpinDown.
     * Requires the caller to own the token.
     * @param _tokenId The ID of the unentangled token.
     */
    function attemptSuperposition(uint256 _tokenId) public {
        _applyDecay(); // Apply decay

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(!_isEntangled[_tokenId], "QET: Token is entangled");

        // Use block data for pseudo-randomness (INSECURE for production)
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenId, "superposition")));

        SpinState newState = (rand % 2 == 0) ? SpinState.SpinUp : SpinState.SpinDown;
        _tokenStates[_tokenId] = newState;

        emit SuperpositionAttempted(_tokenId, newState);
    }

    /**
     * @dev Applies a probabilistic state flip to an unentangled token.
     * Based on pseudo-randomness, the token's state might flip.
     * Requires the caller to own the token.
     * @param _tokenId The ID of the unentangled token.
     */
    function applyQuantumFluctuation(uint256 _tokenId) public {
         _applyDecay(); // Apply decay

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(!_isEntangled[_tokenId], "QET: Token is entangled");
        require(_tokenStates[_tokenId] != SpinState.Uninitialized, "QET: Token state is uninitialized");

        // Use block data for pseudo-randomness (INSECURE for production)
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenId, "fluctuation")));

        // 30% chance to flip state (example probability)
        if (rand % 100 < 30) {
            SpinState currentState = _tokenStates[_tokenId];
            SpinState newState = (currentState == SpinState.SpinUp) ? SpinState.SpinDown : SpinState.SpinUp;
            _tokenStates[_tokenId] = newState;
            emit FluctuationApplied(_tokenId, newState);
        }
        // No event if no flip happens, explicit check might be needed if desired.
    }

     /**
     * @dev Attempts to set two unentangled tokens (owned by the caller) to a specific target state.
     * @param _tokenIdA The ID of the first token.
     * @param _tokenIdB The ID of the second token.
     * @param _targetState The state to attempt to set both tokens to (SpinUp or SpinDown).
     */
    function alignSpins(uint256 _tokenIdA, uint256 _tokenIdB, SpinState _targetState) public {
        _applyDecay(); // Apply decay

        require(_exists(_tokenIdA) && _exists(_tokenIdB), "QET: One or both tokens do not exist");
        require(_tokenIdA != _tokenIdB, "QET: Cannot align a token with itself");
        require(_owners[_tokenIdA] == msg.sender, "QET: Caller does not own token A");
        require(_owners[_tokenIdB] == msg.sender, "QET: Caller does not own token B");
        require(!_isEntangled[_tokenIdA] && !_isEntangled[_tokenIdB], "QET: One or both tokens are entangled");
        require(_targetState != SpinState.Uninitialized, "QET: Target state cannot be Uninitialized");

        _tokenStates[_tokenIdA] = _targetState;
        _tokenStates[_tokenIdB] = _targetState;

        emit SpinsAligned(_tokenIdA, _tokenIdB, _targetState, msg.sender);
    }


    /**
     * @dev Directly flips the state of an unentangled token.
     * Requires the caller to own the token.
     * @param _tokenId The ID of the unentangled token.
     */
    function flipState(uint256 _tokenId) public {
        _applyDecay(); // Apply decay

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(!_isEntangled[_tokenId], "QET: Token is entangled");
        require(_tokenStates[_tokenId] != SpinState.Uninitialized, "QET: Token state is uninitialized");

        SpinState currentState = _tokenStates[_tokenId];
        SpinState newState = (currentState == SpinState.SpinUp) ? SpinState.SpinDown : SpinState.SpinUp;
        _tokenStates[_tokenId] = newState;

        emit StateFlipped(_tokenId, newState);
    }


    // --- Value Dynamics ---

    /**
     * @dev Explicitly triggers the transfer of potential energy from an entangled pair.
     * Requires the caller to own the pair. Energy is transferred to the owner.
     * Can be called after measurement or as a separate step if measurement occurs internally.
     * @param _tokenId A token ID belonging to the pair.
     */
    function collapseEntangledValue(uint256 _tokenId) public {
         _applyDecay(); // Apply decay

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");

        uint256 partnerTokenId = _entangledPartners[_tokenId];
        require(_owners[partnerTokenId] == msg.sender, "QET: Caller does not own partner token"); // Ensure caller owns pair

        uint256 pairId = _getPairId(_tokenId);
        uint256 energyToTransfer = _pairPotentialEnergy[pairId];

        require(energyToTransfer > 0, "QET: No potential energy to collapse");

        _pairPotentialEnergy[pairId] = 0;

        // Transfer Ether from contract balance
        if (address(this).balance >= energyToTransfer) {
            payable(msg.sender).transfer(energyToTransfer);
            emit ValueCollapsed(_tokenId, partnerTokenId, energyToTransfer, msg.sender);
        } else {
             // Log or handle insufficient contract balance - energy is still zeroed out.
             // Could re-add it, or burn it, or leave it. Burning is simplest here.
             emit ValueCollapsed(_tokenId, partnerTokenId, 0, msg.sender); // Emit 0 to show nothing was transferred
        }
    }

    /**
     * @dev Allows the owner of an entangled pair to send Ether to the contract,
     * increasing the pair's potential energy.
     * @param _tokenId A token ID belonging to the pair.
     */
    function boostPotentialEnergy(uint256 _tokenId) public payable {
        _applyDecay(); // Apply decay

        require(msg.value > 0, "QET: Must send Ether to boost");
        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");

        uint256 partnerTokenId = _entangledPartners[_tokenId];
        require(_owners[partnerTokenId] == msg.sender, "QET: Caller does not own partner token"); // Ensure caller owns pair

        uint256 pairId = _getPairId(_tokenId);
        _pairPotentialEnergy[pairId] += msg.value;

        emit PotentialBoosted(_tokenId, partnerTokenId, msg.value, _pairPotentialEnergy[pairId]);
    }

    /**
     * @dev Public function to trigger potential energy decay for all pairs
     * based on the number of blocks passed since the last decay.
     * Can be called by anyone, but applies decay only if sufficient blocks have passed.
     */
    function decayPotentialEnergy() public {
        // _applyDecay includes a check against _lastDecayBlock,
        // so calling it publicly is safe for spam prevention (won't do anything if too soon).
        // A minimum block threshold could be added here if needed.
        _applyDecay();
    }

     /**
     * @dev Represents a hypothetical "state synchronization" operation for an entangled token.
     * In this simulation, it adds a minor potential energy boost to the pair.
     * Requires caller to own the token.
     * @param _tokenId An ID of an entangled token.
     */
    function synchronizeStateWithPartner(uint256 _tokenId) public {
        _applyDecay(); // Apply decay

        require(_exists(_tokenId), "QET: Token does not exist");
        require(_owners[_tokenId] == msg.sender, "QET: Caller does not own the token");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");

        uint256 partnerTokenId = _entangledPartners[_tokenId];
        require(_owners[partnerTokenId] == msg.sender, "QET: Caller does not own partner token"); // Ensure caller owns pair

        uint256 minorBoostAmount = 100; // Example tiny boost in Wei

        uint256 pairId = _getPairId(_tokenId);
        _pairPotentialEnergy[pairId] += minorBoostAmount; // Add a tiny boost

        emit StateSynchronized(_tokenId, partnerTokenId, minorBoostAmount);
    }


    // --- Simplified Admin (Could be restricted to owner in a real contract) ---

    /**
     * @dev Sets the fee required for measureTokenState.
     * In a real contract, this would be restricted to an owner or governance.
     * @param _fee The new measurement fee in Wei.
     */
    function setMeasurementFee(uint256 _fee) public {
        // require(msg.sender == owner(), "Not authorized"); // Example restriction
        _measurementFee = _fee;
    }

    /**
     * @dev Sets the percentage decay rate for potential energy per block.
     * Rate is in per mille (parts per thousand), e.g., 10 = 1%.
     * In a real contract, this would be restricted to an owner or governance.
     * @param _rate The new decay rate (0-1000).
     */
    function setDecayRate(uint256 _rate) public {
        // require(msg.sender == owner(), "Not authorized"); // Example restriction
        require(_rate <= 1000, "QET: Decay rate cannot exceed 100%"); // Rate is /1000 in _applyDecay
        _decayRatePerBlock = _rate;
    }


    // --- Utility & Information (View Functions) ---

    /**
     * @dev Gets the current state of a token.
     * @param _tokenId The ID of the token.
     * @return The SpinState of the token.
     */
    function getTokenState(uint256 _tokenId) public view returns (SpinState) {
        require(_exists(_tokenId), "QET: Token does not exist");
        return _tokenStates[_tokenId];
    }

    /**
     * @dev Gets the ID of the entangled partner token.
     * @param _tokenId The ID of the token.
     * @return The partner token ID, or 0 if not entangled.
     */
    function getEntangledPartner(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "QET: Token does not exist");
        return _entangledPartners[_tokenId];
    }

    /**
     * @dev Checks if a token is currently entangled.
     * @param _tokenId The ID of the token.
     * @return True if the token is entangled, false otherwise.
     */
    function isEntangled(uint256 _tokenId) public view returns (bool) {
         require(_exists(_tokenId), "QET: Token does not exist");
        return _isEntangled[_tokenId];
    }

    /**
     * @dev Gets the owner of a specific token.
     * @param _tokenId The ID of the token.
     * @return The owner address.
     */
    function getOwnerOfToken(uint256 _tokenId) public view returns (address) {
         require(_exists(_tokenId), "QET: Token does not exist");
        return _owners[_tokenId];
    }

    /**
     * @dev Gets the owner of the pair containing _tokenId.
     * Requires the token to be entangled.
     * @param _tokenId A token ID belonging to the pair.
     * @return The owner address of the pair.
     */
    function getOwnerOfPair(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "QET: Token does not exist");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");
        // Assuming both tokens in a pair are owned by the same address
        return _owners[_tokenId];
    }

    /**
     * @dev Gets the current potential energy (Ether) held for the pair.
     * @param _tokenId A token ID belonging to the pair.
     * @return The potential energy amount in Wei.
     */
    function getPotentialEnergyOfPair(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "QET: Token does not exist");
        require(_isEntangled[_tokenId], "QET: Token is not entangled");
        uint256 pairId = _getPairId(_tokenId);
        return _pairPotentialEnergy[pairId];
    }

    /**
     * @dev Gets the total number of individual tokens minted.
     * @return The total supply count.
     */
    function getTotalSupply() public view returns (uint256) {
        return _nextTokenId - 1; // _nextTokenId is the next available ID
    }

     /**
     * @dev Gets the total number of currently active entangled pairs.
     * NOTE: This function is inefficient as it iterates through potential pair IDs.
     * @return The count of entangled pairs.
     */
    function getEntangledPairCount() public view returns (uint256) {
        uint256 count = 0;
         // Iterate through potential pair IDs (the lower ID in the pair)
        for (uint256 pairId = 1; pairId < _nextTokenId; pairId += 2) {
            // Check if the lower ID is entangled, which implies the pair exists
            if (_isEntangled[pairId]) {
                 uint256 partnerId = _entangledPartners[pairId];
                 // Double check validity (basic existence and partner confirms)
                 if (_exists(partnerId) && _entangledPartners[partnerId] == pairId && _isEntangled[partnerId]) {
                    count++;
                 }
            }
        }
        return count;
    }

     /**
     * @dev Gets the total number of tokens not currently entangled.
     * NOTE: This function iterates through all possible token IDs and is inefficient.
     * @return The count of unentangled tokens.
     */
    function getUnentangledTokenCount() public view returns (uint256) {
        uint256 totalTokens = getTotalSupply();
        uint256 entangledTokens = getEntangledPairCount() * 2;
        // Handle cases where totalTokens might be less than entangledTokens temporarily due to minting logic
        if (totalTokens < entangledTokens) return 0;
        return totalTokens - entangledTokens;
    }

    /**
     * @dev Get a list of all token IDs owned by an address.
     * WARNING: This function iterates through an array and can be very gas-intensive
     * for addresses owning a large number of tokens. Use with caution.
     * @param _owner The address to query.
     * @return An array of token IDs owned by the address.
     */
    function listOwnedTokens(address _owner) public view returns (uint256[] memory) {
        // Directly return the stored list (still gas-costly to read/return a large array)
        return _ownedTokens[_owner];
    }

     /**
     * @dev Get a list of the lower token IDs for all entangled pairs owned by an address.
     * Iterates through owned tokens and checks entanglement. Still potentially gas-intensive.
     * @param _owner The address to query.
     * @return An array of the lower token IDs for entangled pairs owned by the address.
     */
    function listOwnedEntangledPairs(address _owner) public view returns (uint256[] memory) {
        uint256[] memory owned = _ownedTokens[_owner];
        uint256[] memory entangledPairs = new uint256[](owned.length / 2); // Max possible pairs

        uint256 pairCount = 0;
        // Iterate through owned tokens and check entanglement
        for (uint256 i = 0; i < owned.length; i++) {
            uint256 tokenId = owned[i];
            if (_isEntangled[tokenId]) {
                uint256 pairId = _getPairId(tokenId);
                 // Add the pairId only once (when we encounter the lower ID)
                if (tokenId == pairId) {
                     entangledPairs[pairCount] = pairId;
                     pairCount++;
                }
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](pairCount);
        for(uint256 i = 0; i < pairCount; i++) {
            result[i] = entangledPairs[i];
        }
        return result;
    }


    // Fallback function to receive Ether
    receive() external payable {
        // Ether sent directly to the contract without a function call
        // could be considered general contract balance, not tied to specific pairs.
        // For this contract, let's assume all received Ether is intended for potential energy.
        // A real contract might differentiate or reject direct sends.
        // For simplicity, we'll just let it increase the contract balance,
        // which is then available for collapsing potential energy.
    }
}
```