Okay, here is a smart contract concept called "QuantumLeapNFT". It's a dynamic NFT that evolves over time, can be "observed" to collapse its state, can undergo rare "quantum leaps," and features simulated "entanglement" between tokens. It's designed to be complex, unique, and non-standard.

It incorporates:
1.  **Dynamic Traits:** Traits are not fixed at mint but change based on on-chain logic.
2.  **State Machine:** NFTs exist in different states (Superposition, Observed, Leaped) that dictate their behavior.
3.  **On-Chain Evolution:** Traits change over time/blocks via a callable function.
4.  **State Collapse (Observation):** A specific action "freezes" certain traits, simulating quantum observation.
5.  **Quantum Leaps:** A costly, rare action that resets the state and potentially drastically changes traits.
6.  **Simulated Entanglement:** Linking two NFTs so their evolutions or leaps might be correlated.
7.  **Dynamic Metadata:** The `tokenURI` reflects the current dynamic state and traits.
8.  **History Tracking:** Counters for observations, leaps, and evolutions.
9.  **Pseudo-Randomness:** Uses block data and transaction details for trait evolution/leaps (with caveats).

It will exceed the 20 function requirement by including standard ERC721 functions, custom state-changing functions, view functions for querying state/traits, admin functions, and internal helpers.

---

**Contract Outline: QuantumLeapNFT**

*   **Purpose:** A dynamic NFT contract where tokens represent "quantum states" that evolve, can be "observed" to fix traits, and can undergo "quantum leaps" or simulated "entanglement".
*   **Core Concepts:** Dynamic Traits, State Machine (Superposition, Observed, Leaped), Time Evolution, State Collapse (Observation), Quantum Leap, Simulated Entanglement, History, Dynamic Metadata.
*   **Inheritance:** ERC721, Ownable, Pausable.
*   **State Variables:**
    *   Token counter.
    *   Mapping for `TokenData` (traits, state, counts, entangled partner).
    *   Mapping for entangled token pairs.
    *   Costs for Quantum Leaps and Entanglement.
    *   Base URI for metadata.
    *   Pseudo-random seed modifier (admin settable, optional).
*   **Structs:** `TokenData` to hold all information per token.
*   **Enums:** `QuantumState` (Superposition, Observed, Leaped).
*   **Events:** Mint, StateChange, TraitsEvolved, LeapPerformed, Entangled, Disentangled, CostUpdated.
*   **Functions (>= 20 total):**
    *   **Admin (Ownable, Pausable):**
        *   `pause()`
        *   `unpause()`
        *   `withdrawFunds()`
        *   `setBaseURI()`
        *   `setLeapCost()`
        *   `setEntangleCost()`
        *   `setRandomSeedModifier()`
    *   **Minting:**
        *   `mintSuperposition()` (Standard mint)
        *   `mintEntangledPair()` (Mints two tokens already entangled)
    *   **Core Logic (State-Changing):**
        *   `evolveState(tokenId)`: Evolves traits based on time/rules. Callable publicly (maybe with incentive?).
        *   `observeState(tokenId)`: Collapses superposition, fixes traits, changes state to Observed. Callable by owner/approved.
        *   `performQuantumLeap(tokenId)`: Changes state to Leaped, then back to Superposition with drastic trait changes. Requires payment. Callable by owner/approved.
        *   `entangleTokens(tokenId1, tokenId2)`: Links two tokens. Requires payment. Callable by owner/approved.
        *   `disentangleTokens(tokenId)`: Breaks entanglement. Callable by owner/approved.
    *   **View/Getter:**
        *   Standard ERC721 views (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`).
        *   `tokenURI(tokenId)`: Generates dynamic metadata URI.
        *   `getTraitA(tokenId)`
        *   `getTraitB(tokenId)`
        *   `getTraitC(tokenId)`
        *   `getQuantumState(tokenId)`
        *   `getObservationCount(tokenId)`
        *   `getLeapCount(tokenId)`
        *   `getEvolutionCount(tokenId)`
        *   `getEntangledWith(tokenId)`
        *   `isEntangled(tokenId)`
        *   `getLeapCost()`
        *   `getEntangleCost()`
    *   **Potential/Simulation Views (Conceptual):**
        *   `predictTraitsAfterEvolution(tokenId)`: Shows potential traits after one evolution step *without* changing state.
        *   `getTraitDiversityScore(tokenId)`: A calculated metric based on traits.
    *   **Internal Helpers:**
        *   `_generateRandomness(seed)`: Handles pseudo-random number generation.
        *   `_applyEvolutionRules(tokenId)`: Logic for slow trait changes.
        *   `_applyLeapRules(tokenId)`: Logic for drastic trait changes.
        *   `_getTraitValues(tokenId)`: Gets current trait values based on state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Using Base64 for dynamic metadata

// --- Contract Outline & Function Summary ---
//
// Contract Name: QuantumLeapNFT
// Purpose: A dynamic NFT collection where tokens represent "quantum states".
//          Tokens evolve over time, can be "observed" to fix traits, undergo
//          "quantum leaps", and can be "entangled" with other tokens.
//
// Core Concepts:
// - Dynamic Traits: Traits change based on on-chain logic.
// - State Machine: Tokens transition through states (Superposition, Observed, Leaped).
// - Time Evolution: Traits evolve over blocks/time via callable function.
// - State Collapse (Observation): An action fixes traits from their current evolved state.
// - Quantum Leap: A costly action resetting the state for a drastic trait change.
// - Simulated Entanglement: Linking tokens affecting shared evolution/leaps.
// - History: Tracking observations, leaps, and evolutions.
// - Dynamic Metadata: `tokenURI` reflects the current state and traits.
// - Pseudo-Randomness: Uses block data & transaction details for trait changes.
//
// Inheritance: ERC721, Ownable, Pausable.
//
// State Variables:
// - _tokenCounter: Manages unique token IDs.
// - _tokenData: Mapping from tokenId to TokenData struct.
// - _entangledTokens: Mapping for entangled pairs (tokenId => tokenId).
// - leapCost: Cost in ether for performing a quantum leap.
// - entangleCost: Cost in ether for entangling tokens.
// - baseURI: Base part of the metadata URI.
// - randomSeedModifier: Admin-set value to influence randomness.
//
// Structs:
// - TokenData: Holds all dynamic data for a single NFT (traits, state, counts, entangled partner).
//
// Enums:
// - QuantumState: Defines the possible states of an NFT (Superposition, Observed, Leaped).
//
// Events:
// - MintedSuperposition(tokenId, owner)
// - MintedEntangledPair(tokenId1, tokenId2, owner)
// - StateChanged(tokenId, oldState, newState)
// - TraitsEvolved(tokenId, evolutionCount)
// - LeapPerformed(tokenId, leapCount, cost)
// - Entangled(tokenId1, tokenId2, cost)
// - Disentangled(tokenId)
// - LeapCostUpdated(newCost)
// - EntangleCostUpdated(newCost)
//
// Functions (>= 20 Total):
//
// 1.  constructor(string name, string symbol)
// 2.  pause() (Admin, Pausable)
// 3.  unpause() (Admin, Pausable)
// 4.  withdrawFunds() (Admin) - Collects ether paid for actions.
// 5.  setBaseURI(string uri) (Admin)
// 6.  setLeapCost(uint256 cost) (Admin)
// 7.  setEntangleCost(uint256 cost) (Admin)
// 8.  setRandomSeedModifier(uint256 modifierValue) (Admin)
// 9.  mintSuperposition(address to) - Mints a new token in Superposition state.
// 10. mintEntangledPair(address to) - Mints two new tokens entangled together.
// 11. evolveState(uint256 tokenId) - Evolves traits for a token based on time/rules. Publicly callable.
// 12. observeState(uint256 tokenId) - Collapses superposition, fixes observed traits, changes state to Observed. Requires owner/approved.
// 13. performQuantumLeap(uint256 tokenId) - Performs a quantum leap. Requires cost payment. Changes state. Requires owner/approved.
// 14. entangleTokens(uint256 tokenId1, uint256 tokenId2) payable - Entangles two tokens. Requires cost payment. Requires owner/approved of both.
// 15. disentangleTokens(uint256 tokenId) - Disentangles a token from its partner. Requires owner/approved.
// 16. tokenURI(uint256 tokenId) view override - Generates dynamic metadata URI based on current state/traits.
// 17. getTraitA(uint256 tokenId) view - Gets value of Trait A.
// 18. getTraitB(uint256 tokenId) view - Gets value of Trait B.
// 19. getTraitC(uint256 tokenId) view - Gets value of Trait C.
// 20. getQuantumState(uint256 tokenId) view - Gets the current state of the token.
// 21. getObservationCount(uint256 tokenId) view - Gets the number of times observed.
// 22. getLeapCount(uint256 tokenId) view - Gets the number of times leaped.
// 23. getEvolutionCount(uint256 tokenId) view - Gets the number of times evolved.
// 24. getEntangledWith(uint256 tokenId) view - Gets the ID of the entangled token (0 if none).
// 25. isEntangled(uint256 tokenId) view - Checks if a token is entangled.
// 26. getLeapCost() view - Gets the current cost for a leap.
// 27. getEntangleCost() view - Gets the current cost for entanglement.
// 28. predictTraitsAfterEvolution(uint256 tokenId) view - Simulates and returns potential traits after one evolution step (no state change).
// 29. getTraitDiversityScore(uint256 tokenId) view - Calculates a conceptual diversity score based on traits.
// --- Inherited ERC721 Functions (provided by OpenZeppelin) ---
// 30. balanceOf(address owner) view override
// 31. ownerOf(uint256 tokenId) view override
// 32. approve(address to, uint256 tokenId) override
// 33. getApproved(uint256 tokenId) view override
// 34. setApprovalForAll(address operator, bool approved) override
// 35. isApprovedForAll(address owner, address operator) view override
// 36. transferFrom(address from, address to, uint256 tokenId) override
// 37. safeTransferFrom(address from, address to, uint256 tokenId) override
// 38. safeTransferFrom(address from, address to, uint256 tokenId, bytes data) override
// --- Internal Helper Functions ---
// 39. _generateRandomness(uint256 seed) pure internal - Pseudo-random generation.
// 40. _applyEvolutionRules(TokenData storage data, uint256 randomness) internal - Logic for evolution.
// 41. _applyLeapRules(TokenData storage data, uint256 randomness) internal - Logic for leaps.
// 42. _getTraitValues(uint256 tokenId) view internal - Helper to get current traits based on state.
// 43. _requireTokenOwnerOrApproved(uint256 tokenId) internal view - Check modifier.
// (Note: Function counts might vary slightly based on internal vs external visibility choices or adding/removing minor getters)

import "hardhat/console.sol"; // Using hardhat console for potential debugging, can be removed for deployment

// --- Error Definitions ---
error NotOwnerOrApproved();
error InvalidQuantumState();
error AlreadyObserved();
error NotInSuperposition();
error IncompatibleStatesForEntanglement();
error CannotEntangleWithSelf();
error NotEntangled();
error AlreadyEntangled();
error InvalidTokenId();
error InsufficientPayment();

// --- Contract Implementation ---

contract QuantumLeapNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenCounter;

    enum QuantumState {
        Superposition, // Traits are dynamic, evolving
        Observed,      // Traits are fixed based on state when observed
        Leaped         // Traits underwent a drastic change via Quantum Leap, back to Superposition behavior (but with new base)
    }

    struct TokenData {
        uint256 tokenId;
        QuantumState state;
        // Traits while in Superposition or Leaped state (evolving)
        uint256 currentTraitA; // Example: 0-100
        uint256 currentTraitB; // Example: 0-255 (byte-like)
        bool currentTraitC;    // Example: boolean flag
        uint256 currentTraitD; // Example: Bitmask/Flags

        // Traits fixed after Observation (only valid in Observed state)
        uint256 observedTraitA;
        uint256 observedTraitB;
        bool observedTraitC;
        uint256 observedTraitD;

        uint64 observationCount;
        uint64 leapCount;
        uint64 evolutionCount; // How many times evolveState was called for this token

        uint256 entangledWith; // 0 if not entangled
    }

    mapping(uint256 => TokenData) private _tokenData;
    mapping(uint256 => uint256) private _entangledTokens; // tokenId => entangled tokenId

    uint256 public leapCost = 0.05 ether;
    uint256 public entangleCost = 0.02 ether;

    string private _baseURI = "";

    // Modifier for pseudo-random seed calculation - allows owner to slightly influence outcomes if needed (be cautious!)
    uint256 public randomSeedModifier = 0;

    // --- Events ---
    event MintedSuperposition(uint256 indexed tokenId, address indexed owner);
    event MintedEntangledPair(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed owner);
    event StateChanged(uint256 indexed tokenId, QuantumState oldState, QuantumState newState);
    event TraitsEvolved(uint256 indexed tokenId, uint64 evolutionCount);
    event LeapPerformed(uint256 indexed tokenId, uint64 leapCount, uint256 cost);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 cost);
    event Disentangled(uint256 indexed tokenId);
    event LeapCostUpdated(uint256 newCost);
    event EntangleCostUpdated(uint256 newCost);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {}

    // --- Modifiers (Custom) ---
    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        _requireTokenOwnerOrApproved(tokenId);
        _;
    }

    function _requireTokenOwnerOrApproved(uint256 tokenId) internal view {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotOwnerOrApproved();
        }
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return super._exists(tokenId); // Use ERC721's existence check
    }

    // --- Admin Functions (Ownable, Pausable) ---

    /// @notice Pauses the contract, preventing state-changing actions.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing state-changing actions.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Withdraws gathered ether from the contract to the owner.
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Sets the base URI for token metadata.
    /// @param uri The new base URI.
    function setBaseURI(string memory uri) public onlyOwner {
        _baseURI = uri;
    }

    /// @notice Sets the cost for performing a Quantum Leap.
    /// @param cost The new cost in wei.
    function setLeapCost(uint256 cost) public onlyOwner {
        leapCost = cost;
        emit LeapCostUpdated(cost);
    }

    /// @notice Sets the cost for Entangling tokens.
    /// @param cost The new cost in wei.
    function setEntangleCost(uint256 cost) public onlyOwner {
        entangleCost = cost;
        emit EntangleCostUpdated(cost);
    }

    /// @notice Sets a modifier value influencing pseudo-randomness. Use with caution.
    /// @param modifierValue The value to add to the randomness seed.
    function setRandomSeedModifier(uint256 modifierValue) public onlyOwner {
        randomSeedModifier = modifierValue;
    }


    // --- Minting Functions ---

    /// @notice Mints a new QuantumLeapNFT in the initial Superposition state.
    /// @param to The address to mint the token to.
    /// @return The ID of the newly minted token.
    function mintSuperposition(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenCounter.increment();
        uint256 newItemId = _tokenCounter.current();

        _mint(to, newItemId);

        // Initialize token data in Superposition
        _tokenData[newItemId].tokenId = newItemId;
        _tokenData[newItemId].state = QuantumState.Superposition;
        // Initial traits based on mint block/time (pseudo-random)
        uint256 initialRandomness = _generateRandomness(newItemId);
        _tokenData[newItemId].currentTraitA = (initialRandomness % 101); // 0-100
        _tokenData[newItemId].currentTraitB = (initialRandomness >> 8) % 256; // 0-255
        _tokenData[newItemId].currentTraitC = (initialRandomness % 2 == 0); // True/False
        _tokenData[newItemId].currentTraitD = (initialRandomness >> 16) % 65536; // 16-bit value

        // Observed traits are undefined initially
        _tokenData[newItemId].observedTraitA = 0;
        _tokenData[newItemId].observedTraitB = 0;
        _tokenData[newItemId].observedTraitC = false;
        _tokenData[newItemId].observedTraitD = 0;

        _tokenData[newItemId].observationCount = 0;
        _tokenData[newItemId].leapCount = 0;
        _tokenData[newItemId].evolutionCount = 0;
        _tokenData[newItemId].entangledWith = 0; // Not entangled initially

        emit MintedSuperposition(newItemId, to);
        emit StateChanged(newItemId, QuantumState.Superposition, QuantumState.Superposition); // State starts as Superposition
        emit TraitsEvolved(newItemId, 0); // Log initial traits

        return newItemId;
    }

    /// @notice Mints two new QuantumLeapNFTs that are immediately entangled.
    /// @param to The address to mint the tokens to.
    /// @return The IDs of the two newly minted and entangled tokens.
    function mintEntangledPair(address to) public onlyOwner whenNotPaused returns (uint256, uint256) {
        _tokenCounter.increment();
        uint256 tokenId1 = _tokenCounter.current();
        _tokenCounter.increment();
        uint256 tokenId2 = _tokenCounter.current();

        _mint(to, tokenId1);
        _mint(to, tokenId2);

        // Initialize token data
        uint256 initialRandomness1 = _generateRandomness(tokenId1);
        uint256 initialRandomness2 = _generateRandomness(tokenId2);

        // Token 1
        _tokenData[tokenId1].tokenId = tokenId1;
        _tokenData[tokenId1].state = QuantumState.Superposition;
        _tokenData[tokenId1].currentTraitA = (initialRandomness1 % 101);
        _tokenData[tokenId1].currentTraitB = (initialRandomness1 >> 8) % 256;
        _tokenData[tokenId1].currentTraitC = (initialRandomness1 % 2 == 0);
        _tokenData[tokenId1].currentTraitD = (initialRandomness1 >> 16) % 65536;
        _tokenData[tokenId1].observationCount = 0;
        _tokenData[tokenId1].leapCount = 0;
        _tokenData[tokenId1].evolutionCount = 0;
        _tokenData[tokenId1].entangledWith = tokenId2;
        _entangledTokens[tokenId1] = tokenId2;

        // Token 2
        _tokenData[tokenId2].tokenId = tokenId2;
        _tokenData[tokenId2].state = QuantumState.Superposition;
        // Apply similar (but slightly different based on randomness source) or potentially correlated rules for entanglement
        _tokenData[tokenId2].currentTraitA = (initialRandomness2 % 101); // Can make rules dependent on partner's initial state too
        _tokenData[tokenId2].currentTraitB = (initialRandomness2 >> 8) % 256;
        _tokenData[tokenId2].currentTraitC = (initialRandomness2 % 2 != 0); // Maybe opposite of partner?
        _tokenData[tokenId2].currentTraitD = ((initialRandomness2 >> 16) + initialRandomness1) % 65536; // Influenced by partner
        _tokenData[tokenId2].observationCount = 0;
        _tokenData[tokenId2].leapCount = 0;
        _tokenData[tokenId2].evolutionCount = 0;
        _tokenData[tokenId2].entangledWith = tokenId1;
        _entangledTokens[tokenId2] = tokenId1;


        emit MintedEntangledPair(tokenId1, tokenId2, to);
        emit StateChanged(tokenId1, QuantumState.Superposition, QuantumState.Superposition);
        emit StateChanged(tokenId2, QuantumState.Superposition, QuantumState.Superposition);
        emit TraitsEvolved(tokenId1, 0);
        emit TraitsEvolved(tokenId2, 0);
        emit Entangled(tokenId1, tokenId2, 0); // No cost for initial mint entanglement

        return (tokenId1, tokenId2);
    }

    // --- Core Logic Functions (State-Changing) ---

    /// @notice Evolves the traits of a token based on on-chain rules.
    ///         Can be called by anyone (potential for gas incentives via relayers or future system).
    /// @param tokenId The ID of the token to evolve.
    function evolveState(uint256 tokenId) public whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();

        TokenData storage data = _tokenData[tokenId];

        // Evolution only happens in Superposition or Leaped states
        if (data.state != QuantumState.Superposition && data.state != QuantumState.Leaped) {
            revert InvalidQuantumState();
        }

        uint256 randomness = _generateRandomness(tokenId);
        _applyEvolutionRules(data, randomness);

        // If entangled, also evolve the partner
        if (data.entangledWith != 0) {
            uint256 partnerId = data.entangledWith;
            if (_exists(partnerId)) {
                 // Generate different randomness for partner evolution, potentially incorporating partner ID
                uint256 partnerRandomness = _generateRandomness(partnerId + randomness);
                _applyEvolutionRules(_tokenData[partnerId], partnerRandomness);
                 // Ensure partner's evolution count is also incremented
                _tokenData[partnerId].evolutionCount++;
                 emit TraitsEvolved(partnerId, _tokenData[partnerId].evolutionCount);
            }
        }

        data.evolutionCount++;
        emit TraitsEvolved(tokenId, data.evolutionCount);
    }


    /// @notice Observes a token, collapsing its state from Superposition to Observed.
    ///         This fixes the traits to their current values.
    /// @param tokenId The ID of the token to observe.
    function observeState(uint256 tokenId) public whenNotPaused onlyTokenOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        TokenData storage data = _tokenData[tokenId];

        if (data.state == QuantumState.Observed) {
            revert AlreadyObserved();
        }
        if (data.state != QuantumState.Superposition && data.state != QuantumState.Leaped) {
             // Should only be callable from Superposition or Leaped
            revert InvalidQuantumState();
        }

        // Collapse state: fix current traits as observed traits
        data.observedTraitA = data.currentTraitA;
        data.observedTraitB = data.currentTraitB;
        data.observedTraitC = data.currentTraitC;
        data.observedTraitD = data.currentTraitD;

        QuantumState oldState = data.state;
        data.state = QuantumState.Observed;
        data.observationCount++;

        // Observation of one might affect entangled partner? Example: forces partner evolution
        if (data.entangledWith != 0) {
            uint256 partnerId = data.entangledWith;
            if (_exists(partnerId) && _tokenData[partnerId].state != QuantumState.Observed) {
                 // Entangled partner is NOT observed, force an evolution upon partner's observation
                 // This is a complex interaction simulation
                uint256 partnerRandomness = _generateRandomness(partnerId + data.tokenId + block.timestamp);
                 _applyEvolutionRules(_tokenData[partnerId], partnerRandomness);
                 _tokenData[partnerId].evolutionCount++;
                 emit TraitsEvolved(partnerId, _tokenData[partnerId].evolutionCount);
            }
        }

        emit StateChanged(tokenId, oldState, data.state);
    }

    /// @notice Performs a Quantum Leap for a token. Resets state and applies drastic trait changes.
    ///         Requires payment of the `leapCost`.
    /// @param tokenId The ID of the token to leap.
    function performQuantumLeap(uint256 tokenId) public payable whenNotPaused onlyTokenOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (msg.value < leapCost) revert InsufficientPayment();

        TokenData storage data = _tokenData[tokenId];

        // Can leap from any state? Let's allow from any state except maybe already Leaped (needs observation first?)
        // Let's simplify: can leap from Superposition or Observed. Leaped state needs to be Observed first to lock traits before another leap.
         if (data.state == QuantumState.Leaped) {
             revert InvalidQuantumState(); // Must Observe after a leap before another leap
         }

        // Refund any excess payment
        if (msg.value > leapCost) {
            payable(msg.sender).transfer(msg.value - leapCost);
        }

        QuantumState oldState = data.state;
        data.state = QuantumState.Leaped; // Briefly enter Leaped state for logging/rules

        uint256 randomness = _generateRandomness(tokenId + block.number); // Use block.number for more entropy source
        _applyLeapRules(data, randomness); // Apply drastic changes

        data.leapCount++;
        // After leap, state reverts back to Superposition for further evolution/observation
        data.state = QuantumState.Superposition;

         // If entangled, potentially influence partner's state/traits
        if (data.entangledWith != 0) {
            uint256 partnerId = data.entangledWith;
            if (_exists(partnerId)) {
                 TokenData storage partnerData = _tokenData[partnerId];
                 // Example Entanglement Leap rule: Partner also evolves drastically, or changes state
                 if (partnerData.state != QuantumState.Observed) {
                     // If partner is not Observed, force a leap on the partner too (without extra cost)
                     uint256 partnerRandomness = _generateRandomness(partnerId + data.tokenId + block.timestamp + block.number);
                     _applyLeapRules(partnerData, partnerRandomness);
                     partnerData.leapCount++;
                     // Partner also goes to Superposition after leap
                     partnerData.state = QuantumState.Superposition;
                     emit LeapPerformed(partnerId, partnerData.leapCount, 0); // Partner leap caused by entanglement (cost absorbed)
                     emit StateChanged(partnerId, partnerData.state, QuantumState.Superposition);
                 } else {
                     // If partner IS Observed, maybe just force a minor evolution?
                    uint256 partnerRandomness = _generateRandomness(partnerId + data.tokenId);
                    _applyEvolutionRules(partnerData, partnerRandomness);
                    partnerData.evolutionCount++;
                    emit TraitsEvolved(partnerId, partnerData.evolutionCount);
                 }
            }
        }


        emit LeapPerformed(tokenId, data.leapCount, leapCost);
        emit StateChanged(tokenId, oldState, data.state);
    }


    /// @notice Entangles two tokens, linking their states.
    ///         Requires payment of the `entangleCost` and ownership/approval of both tokens.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangleTokens(uint256 tokenId1, uint256 tokenId2) public payable whenNotPaused {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert InvalidTokenId();
        if (tokenId1 == tokenId2) revert CannotEntangleWithSelf();
        if (msg.value < entangleCost) revert InsufficientPayment();

        // Check ownership/approval for both tokens
        _requireTokenOwnerOrApproved(tokenId1);
        _requireTokenOwnerOrApproved(tokenId2);

        // Check if already entangled
        if (_tokenData[tokenId1].entangledWith != 0 || _tokenData[tokenId2].entangledWith != 0) revert AlreadyEntangled();

        // Check if states are compatible for entanglement (e.g., both must be Superposition or Leaped, NOT Observed)
         if (_tokenData[tokenId1].state == QuantumState.Observed || _tokenData[tokenId2].state == QuantumState.Observed) {
             revert IncompatibleStatesForEntanglement();
         }


        // Refund any excess payment
        if (msg.value > entangleCost) {
            payable(msg.sender).transfer(msg.value - entangleCost);
        }

        _tokenData[tokenId1].entangledWith = tokenId2;
        _tokenData[tokenId2].entangledWith = tokenId1;
        _entangledTokens[tokenId1] = tokenId2; // Redundant but explicit tracking
        _entangledTokens[tokenId2] = tokenId1;

        emit Entangled(tokenId1, tokenId2, entangleCost);
    }

    /// @notice Disentangles a token from its partner.
    /// @param tokenId The ID of the token to disentangle. Its partner will also be disentangled.
    function disentangleTokens(uint256 tokenId) public whenNotPaused onlyTokenOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        TokenData storage data = _tokenData[tokenId];
        uint256 partnerId = data.entangledWith;

        if (partnerId == 0) revert NotEntangled();
        if (!_exists(partnerId)) {
             // Partner doesn't exist, maybe clean up entanglement?
             data.entangledWith = 0;
             delete _entangledTokens[tokenId];
             emit Disentangled(tokenId);
             return; // Allow disentanglement if partner burned
        }


        TokenData storage partnerData = _tokenData[partnerId];

        // Break the link from both sides
        data.entangledWith = 0;
        partnerData.entangledWith = 0;
        delete _entangledTokens[tokenId];
        delete _entangledTokens[partnerId]; // Should clean up both mappings

        emit Disentangled(tokenId);
        emit Disentangled(partnerId); // Emit for both sides
    }

    // --- ERC721 Overrides ---

    /// @notice Returns the base URI for token metadata.
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /// @notice Generates the dynamic metadata URI for a token.
    /// @param tokenId The ID of the token.
    /// @return The URI pointing to the token's metadata JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            // Return an empty string or error indicator for non-existent tokens
            return ""; // ERC721 standard suggests empty string for non-existent tokens
        }

        TokenData memory data = _tokenData[tokenId];
        (uint256 tA, uint256 tB, bool tC, uint256 tD) = _getTraitValues(tokenId);

        // Build the JSON metadata object string dynamically
        bytes memory json = abi.encodePacked(
            '{"name": "QuantumLeap #', Strings.toString(tokenId), '",',
            '"description": "A dynamic NFT representing a quantum state. Evolves over time, can be observed, leap, or become entangled.",',
            '"image": "', _baseURI, Strings.toString(tokenId), '/image.svg",', // Placeholder image URL
            '"attributes": [',
                '{"trait_type": "State", "value": "',
                    data.state == QuantumState.Superposition ? "Superposition" :
                    data.state == QuantumState.Observed ? "Observed" :
                    "Leaped", '"},',
                '{"trait_type": "Trait A", "value": ', Strings.toString(tA), '},',
                '{"trait_type": "Trait B", "value": ', Strings.toString(tB), '},',
                '{"trait_type": "Trait C", "value": ', tC ? "true" : "false", '},',
                '{"trait_type": "Trait D (Mask)", "value": ', Strings.toString(tD), '},',
                '{"trait_type": "Observations", "value": ', Strings.toString(data.observationCount), '},',
                '{"trait_type": "Leaps", "value": ', Strings.toString(data.leapCount), '},',
                '{"trait_type": "Evolutions", "value": ', Strings.toString(data.evolutionCount), '}',
                data.entangledWith != 0 ? string(abi.encodePacked(', {"trait_type": "Entangled With", "value": ', Strings.toString(data.entangledWith), '}')) : ""
            ,']}'
        );

        // Encode JSON as Base64
        string memory base64Json = Base64.encode(json);

        // Return as data URI
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }


    // --- View/Getter Functions ---

    /// @notice Gets the current value of Trait A for a token based on its state.
    /// @param tokenId The ID of the token.
    /// @return The value of Trait A.
    function getTraitA(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         (uint256 tA, , , ) = _getTraitValues(tokenId);
         return tA;
    }

    /// @notice Gets the current value of Trait B for a token based on its state.
    /// @param tokenId The ID of the token.
    /// @return The value of Trait B.
    function getTraitB(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        (, uint256 tB, , ) = _getTraitValues(tokenId);
        return tB;
    }

    /// @notice Gets the current value of Trait C for a token based on its state.
    /// @param tokenId The ID of the token.
    /// @return The value of Trait C.
    function getTraitC(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        (, , bool tC, ) = _getTraitValues(tokenId);
        return tC;
    }

    /// @notice Gets the current value of Trait D for a token based on its state.
    /// @param tokenId The ID of the token.
    /// @return The value of Trait D.
    function getTraitD(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        (, , , uint256 tD) = _getTraitValues(tokenId);
        return tD;
    }

    /// @notice Gets the current state of a token.
    /// @param tokenId The ID of the token.
    /// @return The QuantumState enum value.
    function getQuantumState(uint256 tokenId) public view returns (QuantumState) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenData[tokenId].state;
    }

    /// @notice Gets the number of times a token has been observed.
    /// @param tokenId The ID of the token.
    /// @return The observation count.
    function getObservationCount(uint256 tokenId) public view returns (uint64) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenData[tokenId].observationCount;
    }

    /// @notice Gets the number of times a token has performed a quantum leap.
    /// @param tokenId The ID of the token.
    /// @return The leap count.
    function getLeapCount(uint256 tokenId) public view returns (uint64) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenData[tokenId].leapCount;
    }

    /// @notice Gets the number of times a token has evolved.
    /// @param tokenId The ID of the token.
    /// @return The evolution count.
    function getEvolutionCount(uint256 tokenId) public view returns (uint64) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _tokenData[tokenId].evolutionCount;
    }

    /// @notice Gets the ID of the token this token is entangled with.
    /// @param tokenId The ID of the token.
    /// @return The entangled token ID (0 if not entangled).
    function getEntangledWith(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0; // Return 0 for non-existent as well
        return _tokenData[tokenId].entangledWith;
    }

    /// @notice Checks if a token is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        return _tokenData[tokenId].entangledWith != 0;
    }

    /// @notice Gets the current cost in wei for performing a Quantum Leap.
    function getLeapCost() public view returns (uint256) {
        return leapCost;
    }

    /// @notice Gets the current cost in wei for Entangling tokens.
    function getEntangleCost() public view returns (uint256) {
        return entangleCost;
    }

    // --- Potential/Simulation View Functions ---

    /// @notice Predicts the traits after one evolution step *without* changing the token's state.
    /// @param tokenId The ID of the token.
    /// @return tuple of (Trait A, Trait B, Trait C, Trait D) after simulated evolution.
    /// @dev Note: This simulation is based on current block data and is not guaranteed
    ///      to be the exact outcome if `evolveState` is called later with different block data.
    function predictTraitsAfterEvolution(uint256 tokenId) public view returns (uint256, uint256, bool, uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        TokenData memory data = _tokenData[tokenId]; // Use memory to avoid state modification
        if (data.state == QuantumState.Observed) {
             // If observed, traits are fixed, evolution doesn't change them.
             return (data.observedTraitA, data.observedTraitB, data.observedTraitC, data.observedTraitD);
        }

        // Simulate evolution rules on a copy of the current traits
        uint256 randomness = _generateRandomness(tokenId + block.timestamp + block.difficulty); // Use different seed for prediction
        // Create a temporary mutable copy of traits for simulation
        uint256 simTraitA = data.currentTraitA;
        uint256 simTraitB = data.currentTraitB;
        bool simTraitC = data.currentTraitC;
        uint256 simTraitD = data.currentTraitD;

        // Apply simplified evolution rules (based on _applyEvolutionRules logic but on memory copy)
        simTraitA = (simTraitA + (randomness % 10)) % 101;
        simTraitB = (simTraitB + (randomness >> 4) % 50) % 256;
        if ((randomness >> 8) % 3 == 0) simTraitC = !simTraitC;
        simTraitD = simTraitD ^ ((randomness >> 12) % 256); // XOR with a random byte

        return (simTraitA, simTraitB, simTraitC, simTraitD);
    }


    /// @notice Calculates a simple diversity score based on the token's current traits.
    /// @param tokenId The ID of the token.
    /// @return A calculated diversity score.
    function getTraitDiversityScore(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        (uint256 tA, uint256 tB, bool tC, uint256 tD) = _getTraitValues(tokenId);

        // Simple arbitrary calculation: sum of numerical traits + 100 if TraitC is true + number of set bits in TraitD
        uint256 score = tA + tB;
        if (tC) {
            score += 100;
        }
        // Count set bits in TraitD (a simplified version)
        uint256 setBits = 0;
        for (uint i = 0; i < 16; i++) {
            if ((tD >> i) & 1 == 1) {
                setBits++;
            }
        }
        score += setBits * 10; // Add 10 for each set bit

        // Maybe add a multiplier based on leap/observation count for 'history' impact
        score += getObservationCount(tokenId) * 50;
        score += getLeapCount(tokenId) * 200;


        return score;
    }


    // --- Internal Helper Functions ---

    /// @notice Generates a pseudo-random number based on block data, sender, and a seed.
    /// @param seed An additional seed value (e.g., token ID, block number).
    /// @return A pseudo-random uint256.
    /// @dev WARNING: On-chain randomness is NOT truly random and can be manipulated by miners/validators,
    ///      especially if used for high-value outcomes predictable in the same block.
    ///      This is suitable for NFT trait variation where strong security isn't paramount.
    function _generateRandomness(uint256 seed) pure internal returns (uint256) {
        // Use block.timestamp, block.difficulty/prevrandao (PoS), msg.sender, tx.origin, nonce, and the seed.
        // block.difficulty is deprecated, use block.prevrandao in PoS. Using a combination for broader compatibility example.
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use block.difficulty for older chains, block.prevrandao for PoS
            msg.sender,
            tx.origin, // Be cautious with tx.origin in some contexts (phishing)
            tx.gasprice,
            block.number,
            seed,
            randomSeedModifier // Include the admin-set modifier
        )));
        return randomness;
    }

    /// @notice Applies the evolution rules to the token's current traits.
    /// @param data The storage struct for the token.
    /// @param randomness A pseudo-random seed for this evolution step.
    internal {
        // Simple evolution rules: traits drift over time/evolution
        data.currentTraitA = (data.currentTraitA + (randomness % 5)) % 101; // Drift Trait A by 0-4
        data.currentTraitB = (data.currentTraitB ^ ((randomness >> 2) % 32)); // XOR Trait B with a small random value
        if ((randomness >> 6) % 5 == 0) data.currentTraitC = !data.currentTraitC; // Flip Trait C with 1/5 probability
        data.currentTraitD = (data.currentTraitD + (randomness >> 8) % 100) % 65536; // Drift Trait D by 0-99

        // Example of Entanglement effect on Evolution:
        // If entangled, traits might drift in a related way (e.g., towards or away from partner)
        if (data.entangledWith != 0) {
            // This would require fetching partner's data, which is expensive in storage loops.
            // A simpler simulation is to make the 'randomness' itself dependent on the partner ID,
            // or just apply slightly different rules.
            // For simplicity here, the entanglement influence is primarily on triggering partner actions (see evolveState).
            // Direct trait correlation would need careful gas consideration or be part of _applyEvolutionRules if called for partner.
        }
    }

     /// @notice Applies the quantum leap rules to the token's current traits.
    /// @param data The storage struct for the token.
    /// @param randomness A pseudo-random seed for this leap.
    internal {
        // Drastic changes based on the leap
        data.currentTraitA = randomness % 101; // Randomize Trait A completely
        data.currentTraitB = (randomness >> 4) % 256; // Randomize Trait B
        data.currentTraitC = (randomness >> 8) % 2 == 0; // Randomize Trait C
        data.currentTraitD = (randomness >> 12) % 65536; // Randomize Trait D

        // Optionally, leaps could slightly influence the base for future evolution based on old state?
        // data.currentTraitA = (data.currentTraitA + data.observedTraitA / 10) % 101; // e.g., influenced by last observed A
    }

    /// @notice Helper to get the currently relevant trait values based on the token's state.
    /// @param tokenId The ID of the token.
    /// @return tuple of (Trait A, Trait B, Trait C, Trait D).
    internal view returns (uint256, uint256, bool, uint256) {
        TokenData memory data = _tokenData[tokenId];
        if (data.state == QuantumState.Observed) {
            // Return observed traits if state is Observed
            return (data.observedTraitA, data.observedTraitB, data.observedTraitC, data.observedTraitD);
        } else {
            // Return current (evolving/leaped) traits otherwise
            return (data.currentTraitA, data.currentTraitB, data.currentTraitC, data.currentTraitD);
        }
    }
}
```