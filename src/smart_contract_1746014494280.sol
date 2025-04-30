Okay, let's create a smart contract concept that focuses on **Dynamic NFTs with Simulated Quantum Entanglement and State Collapse**.

This contract will define NFTs whose traits are not static but can change based on interactions, time, and their relationship with other NFTs. The core mechanic is "entanglement" between two NFTs, where actions on one can probabilistically or deterministically affect the other, simulating a simplified quantum link. There's also a concept of "state collapse" where an NFT can become non-dynamic under certain conditions.

This concept is creative because it moves beyond static or purely generative NFTs, advanced due to the interconnected state changes and delegated interaction rights, and trendy by leveraging dynamic traits and unique interaction mechanics. It avoids direct duplication of standard ERC721/ERC1155 or common DeFi/DAO patterns.

---

## Quantum Entangled NFT (QENFT) Contract Outline

1.  **Contract Description:** An ERC721-compliant contract for dynamic NFTs with traits that change based on internal state, time, interactions, and entanglement with another QENFT. Features include entanglement, state observation/manipulation, trait synchronization, state collapse, and delegated interaction rights.
2.  **Inheritance:** ERC721, ERC721Enumerable, ERC721URIStorage, Ownable.
3.  **State Variables:** Mappings for traits, entanglement status, delegated rights, last interaction time, collapsed state status, contract parameters (costs, probabilities, rates).
4.  **Structs & Enums:** Define the structure for dynamic traits (e.g., stability, energy, frequency, coherence, potential state), and possibly enums for state types.
5.  **Events:** Emit events for significant actions like minting, trait changes, entanglement, disentanglement, state collapse, delegation.
6.  **Core Logic:**
    *   Minting (Owner restricted).
    *   Trait Management: Internal functions to update traits based on specific actions.
    *   Time-Based Dynamics: Mechanisms for traits (like energy or coherence) to decay or regenerate over time if not interacted with. Checked upon interaction.
    *   Entanglement: Functions to link two NFTs. Requires payment and owner consent/approval.
    *   Disentanglement: Functions to break the link. Triggered manually or upon transfer.
    *   Interactions: Functions like `observe`, `charge`, `discharge`, `synchronizeFrequency`, `triggerQuantumFluctuation` that modify traits of the called token and potentially its entangled pair based on rules and probabilities.
    *   State Collapse: A function to make an NFT's traits static if certain conditions are met (e.g., high stability, coherence).
    *   Delegation: Allowing other addresses to perform interaction functions on an owner's behalf for a limited time.
    *   Admin: Functions for the owner to set contract parameters (costs, probabilities, decay/regen rates) and withdraw collected fees.
    *   View Functions: Get traits, check entanglement status, check delegation, etc.
7.  **ERC721 Overrides:** Handle disentanglement in `_beforeTokenTransfer`.

---

## Function Summary

This list includes the custom functions beyond standard ERC721, aiming for >= 20 unique actions/queries.

1.  `constructor()`: Initializes the contract, sets owner.
2.  `safeMint(address to, uint256 tokenId, string memory uri)`: Mints a new QENFT, setting initial random-ish traits and URI. (Owner-only)
3.  `getTraits(uint256 tokenId)`: Returns the dynamic traits of an NFT. (View)
4.  `getDynamicTrait(uint256 tokenId, uint8 traitType)`: Returns a specific dynamic trait by type enum/index. (View)
5.  `setTokenName(uint256 tokenId, string memory name)`: Sets a custom name for the NFT. (Owner-only)
6.  `getTokenName(uint256 tokenId)`: Gets the custom name of the NFT. (View)
7.  `generateDynamicName(uint256 tokenId)`: Generates a potential name string based on current dynamic traits (for display purposes, off-chain friendly). (View)
8.  `entangle(uint256 tokenId1, uint256 tokenId2)`: Attempts to entangle two *unentangled* NFTs. Requires ownership or approval for both and payment of `entanglementCost`.
9.  `disentangle(uint256 tokenId)`: Breaks the entanglement for the pair including `tokenId`. Callable by either owner in the pair.
10. `getEntangledPair(uint256 tokenId)`: Returns the token ID of the NFT entangled with `tokenId`, or 0 if not entangled. (View)
11. `isEntangled(uint256 tokenId)`: Returns true if the token is currently entangled. (View)
12. `observe(uint256 tokenId)`: Interacts with the NFT, simulating quantum observation. Triggers trait changes based on `frequency`, `potentialState`, and affects entangled pair. Costs energy.
13. `charge(uint256 tokenId)`: Increases the `energy` trait. May affect `frequency` or `potentialState` volatility and ripple to the entangled pair. Costs Ether/tokens (or just action, TBD). Let's make it cost Ether. (Payable)
14. `discharge(uint256 tokenId)`: Decreases the `energy` trait. May increase `stability` or lock `potentialState`. Ripples to entangled pair.
15. `synchronizeFrequency(uint256 tokenId)`: Attempts to align `frequency` with the entangled pair. Success probability depends on `coherence`. Success boosts `coherence`, failure reduces it. Costs energy.
16. `destabilize(uint256 tokenId)`: Lowers `stability`, potentially increasing trait volatility. May be an outcome of other interactions or a standalone action. Costs energy.
17. `triggerQuantumFluctuation(uint256 tokenId)`: A rare, potentially costly action that significantly randomizes traits and `potentialState`. High risk, potentially high reward. Costs `fluctuationCost`. (Payable)
18. `collapseState(uint256 tokenId)`: Attempts to make the NFT's traits non-dynamic. Requires high `stability` and `coherence`. Irreversible. Costs energy/fee. (Payable)
19. `isStateCollapsed(uint256 tokenId)`: Returns true if the NFT's state has been collapsed. (View)
20. `delegateInteraction(uint256 tokenId, address delegate, uint64 duration)`: Allows `delegate` to call interaction functions (`observe`, `charge`, etc.) on `tokenId` for `duration` seconds. (Owner-only)
21. `revokeInteraction(uint256 tokenId, address delegate)`: Revokes interaction rights from a delegate. (Owner-only)
22. `checkInteractionDelegate(uint256 tokenId, address delegate)`: Returns the expiration timestamp if `delegate` has interaction rights for `tokenId`, otherwise 0. (View)
23. `getLastInteractionTime(uint256 tokenId)`: Returns the timestamp of the last significant interaction. Used for decay/regen calculations. (View)
24. `setEntanglementCost(uint256 cost)`: Sets the Ether cost to entangle two NFTs. (Owner-only)
25. `setFluctuationCost(uint256 cost)`: Sets the Ether cost for `triggerQuantumFluctuation`. (Owner-only)
26. `setDecayRates(...)`: Sets parameters for trait decay over time. (Owner-only)
27. `setRegenerationRates(...)`: Sets parameters for energy/coherence regeneration. (Owner-only)
28. `setProbabilities(...)`: Sets probabilities for outcomes of interaction functions (e.g., success rate of sync, magnitude of change). (Owner-only)
29. `withdrawFees()`: Allows the owner to withdraw collected Ether fees. (Owner-only)
30. `_beforeTokenTransfer(...)`: Internal override to handle disentanglement before any transfer.

---

## Smart Contract Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Note: On-chain randomness is limited and predictable.
// The pseudo-randomness used here (`_generateRandomness`) is for demonstration
// and should NOT be used for high-security or high-value randomness requirements.
// For production, consider Chainlink VRF or similar solutions.

contract QuantumEntangledNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256; // For min/max/average operations
    using ECDSA for bytes32; // Example of using ECDSA for potential future features (not directly used in current functions)

    Counters.Counter private _tokenIdCounter;

    // --- Constants & Configuration ---
    uint224 public entanglementCost = 0.01 ether;
    uint224 public fluctuationCost = 0.05 ether;
    uint224 public collapseCost = 0.02 ether;

    uint256 public constant MAX_ENERGY = 1000;
    uint256 public constant MAX_STABILITY = 100;
    uint256 public constant MAX_FREQUENCY = 100;
    uint256 public constant MAX_COHERENCE = 100;

    // Decay/Regen rates per hour (scaled by 100 for decimal precision)
    uint256 public energyRegenRatePerHour = 50; // 0.5 per hour
    uint256 public coherenceRegenRatePerHour = 10; // 0.1 per hour
    uint256 public energyDecayRatePerHour = 20; // 0.2 per hour (if below threshold?)
    uint256 public coherenceDecayRatePerHour = 5; // 0.05 per hour (if below threshold?)
    uint256 public stabilityDecayRatePerHour = 1; // 0.01 per hour (very slow)

    // Probabilities (scaled by 1000 for precision, e.g., 500 = 50%)
    uint256 public syncSuccessProbability = 750; // 75% success if coherence is MAX_COHERENCE
    uint256 public fluctuationProbability = 10; // 1% chance on interaction
    uint256 public entanglementRippleProbability = 800; // 80% chance interaction affects pair

    // --- Structs & Enums ---
    enum PotentialState { Undetermined, StateA, StateB, StateC }

    struct NFTTraits {
        uint256 stability; // Resilience to chaotic changes (0-100)
        uint256 energy;    // Resource for performing actions (0-1000)
        uint256 frequency; // Rate of potential state change/vibration (0-100)
        uint256 coherence; // Strength of link to entangled pair, state clarity (0-100)
        PotentialState potentialState; // The state the NFT is tending towards or could collapse into
    }

    enum TraitType { Stability, Energy, Frequency, Coherence, PotentialState }

    // --- State Variables ---
    mapping(uint256 => NFTTraits) private _tokenTraits;
    mapping(uint256 => uint256) private _entangledPair; // tokenId => pairedTokenId (0 if not entangled)
    mapping(uint256 => string) private _tokenNames; // Optional custom names
    mapping(uint256 => uint64) private _lastInteractionTime; // Timestamp of last interaction
    mapping(uint256 => bool) private _isStateCollapsed; // True if traits are static
    mapping(uint256 => mapping(address => uint64)) private _interactionDelegates; // tokenId => delegateAddress => expirationTimestamp

    // --- Events ---
    event TraitsChanged(uint256 indexed tokenId, NFTTraits newTraits);
    event Entangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StateCollapsed(uint256 indexed tokenId);
    event InteractionDelegated(uint256 indexed tokenId, address indexed delegate, uint64 expiration);
    event InteractionRevoked(uint256 indexed tokenId, address indexed delegate);
    event QuantumFluctuationTriggered(uint256 indexed tokenId);
    event EnergySpent(uint256 indexed tokenId, uint256 amount);
    event EnergyRegenerated(uint256 indexed tokenId, uint256 amount);
    event TraitDecayed(uint256 indexed tokenId, TraitType traitType, uint256 amount);

    // --- Modifiers ---
    modifier whenNotCollapsed(uint256 tokenId) {
        require(!_isStateCollapsed[tokenId], "QENFT: State is collapsed");
        _;
    }

    modifier onlyInteractionDelegate(uint256 tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || _interactionDelegates[tokenId][msg.sender] > block.timestamp,
            "QENFT: Not owner or delegate"
        );
        _;
    }

    // --- Constructor ---
    constructor() ERC721("QuantumEntangledNFT", "QENFT") Ownable(msg.sender) {}

    // --- Internal Helpers ---

    function _generateRandomness(uint256 seed) internal view returns (uint256) {
        // Basic pseudo-randomness. NOT suitable for security-critical applications.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdCounter.current(), seed)));
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _getElapsedHours(uint256 tokenId) internal view returns (uint256) {
        uint64 lastTime = _lastInteractionTime[tokenId];
        if (lastTime == 0) return 0; // No previous interaction recorded

        // Avoid issues with block.timestamp potentially decreasing in some scenarios (unlikely on mainnet, but good practice)
        if (block.timestamp <= lastTime) return 0;

        return (block.timestamp - lastTime) / 3600; // Hours since last interaction
    }

    function _applyTimeBasedDynamics(uint256 tokenId) internal {
        uint256 elapsedHours = _getElapsedHours(tokenId);
        if (elapsedHours == 0) return;

        NFTTraits storage traits = _tokenTraits[tokenId];

        // Apply Regeneration
        uint256 energyRegen = (energyRegenRatePerHour * elapsedHours) / 100;
        uint256 coherenceRegen = (coherenceRegenRatePerHour * elapsedHours) / 100;
        traits.energy = Math.min(traits.energy + energyRegen, MAX_ENERGY);
        traits.coherence = Math.min(traits.coherence + coherenceRegen, MAX_COHERENCE);

        // Apply Decay (Example: decay only happens if energy is low or coherence is low?)
        // Let's make it general decay for simplicity based on being static
         uint256 stabilityDecay = (stabilityDecayRatePerHour * elapsedHours) / 100;
         uint256 energyDecay = (energyDecayRatePerHour * elapsedHours) / 100;
         uint256 coherenceDecay = (coherenceDecayRatePerHour * elapsedHours) / 100;

         traits.stability = (traits.stability > stabilityDecay) ? traits.stability - stabilityDecay : 0;
         traits.energy = (traits.energy > energyDecay) ? traits.energy - energyDecay : 0;
         traits.coherence = (traits.coherence > coherenceDecay) ? traits.coherence - coherenceDecay : 0;


        // Note: Frequency decay/regen could also be added

        _lastInteractionTime[tokenId] = uint64(block.timestamp);
        emit TraitsChanged(tokenId, traits);
    }

     function _spendEnergy(uint256 tokenId, uint256 amount) internal whenNotCollapsed(tokenId) {
        NFTTraits storage traits = _tokenTraits[tokenId];
        require(traits.energy >= amount, "QENFT: Insufficient energy");
        traits.energy -= amount;
        emit EnergySpent(tokenId, amount);
        emit TraitsChanged(tokenId, traits); // Emit traits changed after energy update
    }


    function _applyEntanglementRipple(uint256 tokenId, uint256 seed) internal whenNotCollapsed(tokenId) {
        uint256 pairId = _entangledPair[tokenId];
        if (pairId == 0) return; // Not entangled

        if (_generateRandomness(seed) % 1000 < entanglementRippleProbability) {
            // Simulate ripple effect - this is where creative effects happen
            NFTTraits storage traits = _tokenTraits[tokenId];
            NFTTraits storage pairTraits = _tokenTraits[pairId];

            // Example Ripple Effects:
            // 1. Energy Transfer (small amount, probabilistic direction)
            if (traits.energy > 10 && pairTraits.energy < MAX_ENERGY - 10 && _generateRandomness(seed + 1) % 2 == 0) {
                uint256 transferAmount = Math.min(traits.energy / 10, (MAX_ENERGY - pairTraits.energy));
                 transferAmount = Math.min(transferAmount, 50); // Cap transfer amount
                traits.energy -= transferAmount;
                pairTraits.energy += transferAmount;
                 emit EnergySpent(tokenId, transferAmount); // Log as spent from source
                 emit EnergyRegenerated(pairId, transferAmount); // Log as regenerated on destination
            } else if (pairTraits.energy > 10 && traits.energy < MAX_ENERGY - 10) {
                 uint256 transferAmount = Math.min(pairTraits.energy / 10, (MAX_ENERGY - traits.energy));
                 transferAmount = Math.min(transferAmount, 50); // Cap transfer amount
                 pairTraits.energy -= transferAmount;
                traits.energy += transferAmount;
                 emit EnergySpent(pairId, transferAmount); // Log as spent from source
                 emit EnergyRegenerated(tokenId, transferAmount); // Log as regenerated on destination
            }


            // 2. Frequency Synchronization Nudge (pushing towards average)
            if (traits.frequency != pairTraits.frequency) {
                 uint256 avgFrequency = (traits.frequency + pairTraits.frequency) / 2;
                 traits.frequency = (traits.frequency + avgFrequency) / 2; // Nudge freq towards average
                 pairTraits.frequency = (pairTraits.frequency + avgFrequency) / 2; // Nudge pair freq towards average
            }

            // 3. Potential State Alignment (probabilistic influence)
            if (traits.potentialState != pairTraits.potentialState) {
                 if (_generateRandomness(seed + 2) % 100 < traits.coherence/2) { // Higher coherence = higher chance of alignment
                     pairTraits.potentialState = traits.potentialState;
                 } else if (_generateRandomness(seed + 3) % 100 < pairTraits.coherence/2) {
                     traits.potentialState = pairTraits.potentialState;
                 }
            }

            // 4. Stability/Coherence Fluctuation (small random change based on interaction)
             uint256 randomChange = _generateRandomness(seed + 4) % 10 - 5; // Change between -5 and +5
             traits.stability = uint265(Math.min(Math.max(int256(traits.stability) + int256(randomChange), 0), int256(MAX_STABILITY)));
             randomChange = _generateRandomness(seed + 5) % 10 - 5;
             traits.coherence = uint256(Math.min(Math.max(int256(traits.coherence) + int256(randomChange), 0), int256(MAX_COHERENCE)));

             randomChange = _generateRandomness(seed + 6) % 10 - 5; // Change between -5 and +5 for pair
             pairTraits.stability = uint256(Math.min(Math.max(int256(pairTraits.stability) + int256(randomChange), 0), int256(MAX_STABILITY)));
             randomChange = _generateRandomness(seed + 7) % 10 - 5;
             pairTraits.coherence = uint256(Math.min(Math.max(int256(pairTraits.coherence) + int256(randomChange), 0), int256(MAX_COHERENCE)));


            // Emit changes for both tokens
            emit TraitsChanged(tokenId, traits);
            emit TraitsChanged(pairId, pairTraits);
        }
    }


    // --- ERC721 Standard Overrides ---

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super._baseURI();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
         string memory base = _baseURI();
        string memory customName = _tokenNames[tokenId];
        NFTTraits memory traits = _tokenTraits[tokenId];

        // Example dynamic URI based on traits and name
        // In a real dApp, this would likely return a pointer (IPFS hash, API endpoint)
        // where dynamic metadata is generated based on on-chain traits.
        // Here, we just return a placeholder demonstrating dynamism.
        string memory dynamicPart = string(abi.encodePacked(
            "&stability=", toString(traits.stability),
            "&energy=", toString(traits.energy),
            "&frequency=", toString(traits.frequency),
            "&coherence=", toString(traits.coherence),
            "&state=", toString(uint8(traits.potentialState)), // Enum to uint
             "&collapsed=", _isStateCollapsed[tokenId] ? "true" : "false",
            "&name=", bytes(customName).length > 0 ? customName : "Unnamed"
        ));

        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, toString(tokenId), dynamicPart));
        } else {
             // Fallback or construct a data URI (expensive!) - better to use a base URI
             return string(abi.encodePacked("data:application/json;base64,...", toString(tokenId), dynamicPart)); // Simplified
        }
    }

     // Helper function to convert uint256 to string (simplified)
    function toString(uint256 value) internal pure returns (string memory) {
        // This is a placeholder. Use a safe library like OpenZeppelin's Strings.
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }


    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Ensure entanglement is broken on transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (_entangledPair[tokenId] != 0) {
            // Disentangle when transferred
            uint256 pairId = _entangledPair[tokenId];
            _entangledPair[tokenId] = 0;
            _entangledPair[pairId] = 0;
            emit Disentangled(tokenId, pairId);
        }
         // Reset delegation rights on transfer
         delete _interactionDelegates[tokenId];

         // Optionally, apply decay before transfer if it hasn't been checked recently
         _applyTimeBasedDynamics(tokenId);
    }


    // --- Custom Functions ---

    /// @notice Mints a new Quantum Entangled NFT.
    /// @param to The address receiving the NFT.
    /// @param uri The metadata URI for the NFT.
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // Initialize traits with some baseline values
        NFTTraits storage traits = _tokenTraits[tokenId];
        // Use pseudo-randomness for initial traits
        uint256 initialSeed = _generateRandomness(tokenId + 100);
        traits.stability = (initialSeed % MAX_STABILITY) + 1; // Avoid 0
        traits.energy = (initialSeed % MAX_ENERGY) + 50; // Start with some energy
        traits.frequency = (initialSeed % MAX_FREQUENCY) + 1;
        traits.coherence = (initialSeed % MAX_COHERENCE) + 1;
        traits.potentialState = PotentialState(initialSeed % 3); // Random initial state (0, 1, or 2)

        _lastInteractionTime[tokenId] = uint64(block.timestamp);
        _isStateCollapsed[tokenId] = false; // Ensure it starts dynamic

        emit TraitsChanged(tokenId, traits);
    }

     /// @notice Gets all dynamic traits for a specific NFT.
     /// @param tokenId The ID of the token.
     /// @return A struct containing all current trait values.
    function getTraits(uint256 tokenId) public view returns (NFTTraits memory) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _tokenTraits[tokenId];
    }

     /// @notice Gets a specific dynamic trait for an NFT by type.
     /// @param tokenId The ID of the token.
     /// @param traitType The type of trait to retrieve (enum TraitType).
     /// @return The value of the specified trait.
    function getDynamicTrait(uint256 tokenId, TraitType traitType) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        NFTTraits memory traits = _tokenTraits[tokenId];
        if (traitType == TraitType.Stability) return traits.stability;
        if (traitType == TraitType.Energy) return traits.energy;
        if (traitType == TraitType.Frequency) return traits.frequency;
        if (traitType == TraitType.Coherence) return traits.coherence;
        // PotentialState is an enum, cast to uint256 for generic return
        if (traitType == TraitType.PotentialState) return uint256(traits.potentialState);
        revert("QENFT: Invalid trait type");
    }


    /// @notice Sets a custom name for the NFT.
    /// @param tokenId The ID of the token.
    /// @param name The name to set.
    function setTokenName(uint256 tokenId, string memory name) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QENFT: Caller is not owner or approved");
        _tokenNames[tokenId] = name;
    }

    /// @notice Gets the custom name of the NFT.
    /// @param tokenId The ID of the token.
    /// @return The custom name string.
    function getTokenName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _tokenNames[tokenId];
    }

    /// @notice Generates a potential name based on current dynamic traits (for display/off-chain metadata).
    /// @param tokenId The ID of the token.
    /// @return A string representing a possible generated name.
    function generateDynamicName(uint256 tokenId) public view returns (string memory) {
         require(_exists(tokenId), "QENFT: Token does not exist");
         NFTTraits memory traits = _tokenTraits[tokenId];
         string memory baseName = "Qubit ";
         string memory stateDesc;

         if (_isStateCollapsed[tokenId]) {
             stateDesc = "Collapsed ";
         } else {
             if (traits.potentialState == PotentialState.Undetermined) stateDesc = "Flickering ";
             else if (traits.potentialState == PotentialState.StateA) stateDesc = "Alpha ";
             else if (traits.potentialState == PotentialState.StateB) stateDesc = "Beta ";
             else if (traits.potentialState == PotentialState.StateC) stateDesc = "Gamma ";
         }

         string memory traitSuffix = string(abi.encodePacked(
             "| S:", toString(traits.stability),
             " E:", toString(traits.energy),
             " F:", toString(traits.frequency),
             " C:", toString(traits.coherence),
             " |"
         ));

         return string(abi.encodePacked(baseName, stateDesc, toString(tokenId), traitSuffix));
    }


    /// @notice Attempts to entangle two unentangled NFTs.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangle(uint256 tokenId1, uint256 tokenId2) public payable {
        require(_exists(tokenId1), "QENFT: Token 1 does not exist");
        require(_exists(tokenId2), "QENFT: Token 2 does not exist");
        require(tokenId1 != tokenId2, "QENFT: Cannot entangle token with itself");
        require(_entangledPair[tokenId1] == 0, "QENFT: Token 1 is already entangled");
        require(_entangledPair[tokenId2] == 0, "QENFT: Token 2 is already entangled");

        // Require approval or ownership of both tokens by msg.sender
        require(_isApprovedOrOwner(msg.sender, tokenId1), "QENFT: Caller not owner or approved for Token 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "QENFT: Caller not owner or approved for Token 2");

        require(msg.value >= entanglementCost, "QENFT: Insufficient entanglement cost");

        // Check/apply time-based dynamics before entanglement
        _applyTimeBasedDynamics(tokenId1);
        _applyTimeBasedDynamics(tokenId2);

        _entangledPair[tokenId1] = tokenId2;
        _entangledPair[tokenId2] = tokenId1;

        // Nudge coherence/frequency upon entanglement? Example:
        NFTTraits storage traits1 = _tokenTraits[tokenId1];
        NFTTraits storage traits2 = _tokenTraits[tokenId2];
        traits1.coherence = Math.min(traits1.coherence + 10, MAX_COHERENCE);
        traits2.coherence = Math.min(traits2.coherence + 10, MAX_COHERENCE);
         traits1.frequency = (traits1.frequency + traits2.frequency) / 2;
         traits2.frequency = traits1.frequency; // Set both to the average

        emit TraitsChanged(tokenId1, traits1);
        emit TraitsChanged(tokenId2, traits2);

        emit Entangled(tokenId1, tokenId2);
    }

    /// @notice Breaks the entanglement for a pair of NFTs.
    /// @param tokenId The ID of one token in the pair.
    function disentangle(uint256 tokenId) public {
        require(_exists(tokenId), "QENFT: Token does not exist");
        uint256 pairId = _entangledPair[tokenId];
        require(pairId != 0, "QENFT: Token is not entangled");
        require(_isApprovedOrOwner(msg.sender, tokenId), "QENFT: Caller not owner or approved");

        // Apply time-based dynamics before disentangling
        _applyTimeBasedDynamics(tokenId);
        _applyTimeBasedDynamics(pairId);


        _entangledPair[tokenId] = 0;
        _entangledPair[pairId] = 0;

        // Nudge traits away from each other upon disentanglement? Example:
        NFTTraits storage traits1 = _tokenTraits[tokenId];
        NFTTraits storage traits2 = _tokenTraits[pairId];
        traits1.coherence = (traits1.coherence > 10) ? traits1.coherence - 10 : 0;
        traits2.coherence = (traits2.coherence > 10) ? traits2.coherence - 10 : 0;
         // Frequency might become more independent

         emit TraitsChanged(tokenId, traits1);
         emit TraitsChanged(pairId, traits2);

        emit Disentangled(tokenId, pairId);
    }

    /// @notice Gets the token ID of the NFT entangled with the given token.
    /// @param tokenId The ID of the token.
    /// @return The token ID of the entangled pair, or 0 if not entangled.
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _entangledPair[tokenId];
    }

    /// @notice Checks if a token is entangled with another specific token.
    /// @param tokenId The ID of the token.
    /// @param potentialPairId The ID of the token to check against.
    /// @return True if they are entangled, false otherwise.
    function isEntangledWith(uint256 tokenId, uint256 potentialPairId) public view returns (bool) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        require(_exists(potentialPairId), "QENFT: Potential pair token does not exist");
        return _entangledPair[tokenId] == potentialPairId;
    }

    /// @notice Checks if a token is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _entangledPair[tokenId] != 0;
    }


    /// @notice Interacts with the NFT, simulating quantum observation and triggering dynamic changes.
    /// Applies decay/regen, spends energy, updates traits, and ripples to entangled pair.
    /// @param tokenId The ID of the token to observe.
    function observe(uint256 tokenId) public onlyInteractionDelegate(tokenId) whenNotCollapsed(tokenId) {
        require(_exists(tokenId), "QENFT: Token does not exist");

        _applyTimeBasedDynamics(tokenId); // Apply decay/regen before the action

        uint256 energyCost = 50; // Example cost
        _spendEnergy(tokenId, energyCost);

        NFTTraits storage traits = _tokenTraits[tokenId];
        uint256 randomness = _generateRandomness(tokenId + block.timestamp);

        // Simulate Observer Effect: Observing might nudge the state towards one
        // based on current potentialState and frequency/coherence
        uint265 stateNudgeAmount = traits.frequency / 10; // Higher freq = bigger potential nudge
        if (randomness % 100 < stateNudgeAmount) {
            // Probabilistic state change based on potentialState
            if (traits.potentialState == PotentialState.Undetermined) {
                traits.potentialState = PotentialState(randomness % 3 + 1); // Nudge towards A, B, or C
            } else {
                // Nudge towards current state or nearby state
                 if (randomness % 2 == 0) {
                      traits.potentialState = PotentialState(uint8(traits.potentialState)); // Reinforce current state
                 } else {
                      // Small chance to shift to a different state
                      traits.potentialState = PotentialState(randomness % 3 + 1);
                 }
            }
        }

        // Apply some small random change to stability/coherence as a result of observation
        int256 stabilityChange = int256(randomness % 10) - 5; // Change between -5 and +5
        int256 coherenceChange = int256(randomness % 12) - 6; // Change between -6 and +6

        traits.stability = uint256(Math.min(Math.max(int256(traits.stability) + stabilityChange, 0), int256(MAX_STABILITY)));
        traits.coherence = uint256(Math.min(Math.max(int256(traits.coherence) + coherenceChange, 0), int256(MAX_COHERENCE)));


        _applyEntanglementRipple(tokenId, randomness + 1); // Ripple effect to pair

        _lastInteractionTime[tokenId] = uint64(block.timestamp); // Update last interaction time
        emit TraitsChanged(tokenId, traits);
    }

    /// @notice Adds energy to the NFT.
    /// @param tokenId The ID of the token to charge.
    function charge(uint256 tokenId) public onlyInteractionDelegate(tokenId) whenNotCollapsed(tokenId) {
         require(_exists(tokenId), "QENFT: Token does not exist");

        _applyTimeBasedDynamics(tokenId); // Apply decay/regen

        uint256 energyGain = 100; // Example energy gained per charge action
        NFTTraits storage traits = _tokenTraits[tokenId];
        traits.energy = Math.min(traits.energy + energyGain, MAX_ENERGY);

        uint256 randomness = _generateRandomness(tokenId + block.timestamp + 1);

        // Charging might increase frequency or stability based on energy level
        if (traits.energy > MAX_ENERGY / 2) {
             traits.frequency = Math.min(traits.frequency + 5, MAX_FREQUENCY);
        } else {
             traits.stability = Math.min(traits.stability + 3, MAX_STABILITY);
        }

        _applyEntanglementRipple(tokenId, randomness + 1); // Ripple effect

        _lastInteractionTime[tokenId] = uint64(block.timestamp);
        emit TraitsChanged(tokenId, traits);
    }

    /// @notice Discharges energy from the NFT.
    /// @param tokenId The ID of the token to discharge.
    function discharge(uint256 tokenId) public onlyInteractionDelegate(tokenId) whenNotCollapsed(tokenId) {
         require(_exists(tokenId), "QENFT: Token does not exist");

        _applyTimeBasedDynamics(tokenId); // Apply decay/regen

        uint256 energyLoss = 75; // Example energy loss
        _spendEnergy(tokenId, energyLoss); // Use _spendEnergy to handle check

        NFTTraits storage traits = _tokenTraits[tokenId];
        uint256 randomness = _generateRandomness(tokenId + block.timestamp + 2);

        // Discharging might increase stability or clarity of state
        if (traits.energy < MAX_ENERGY / 4) {
             traits.stability = Math.min(traits.stability + 10, MAX_STABILITY);
             // Small chance to make state more determined if low energy?
             if (traits.potentialState == PotentialState.Undetermined && randomness % 10 < 3) {
                 traits.potentialState = PotentialState(randomness % 3 + 1);
             }
        } else {
             traits.coherence = Math.min(traits.coherence + 5, MAX_COHERENCE);
        }

        _applyEntanglementRipple(tokenId, randomness + 1); // Ripple effect

        _lastInteractionTime[tokenId] = uint64(block.timestamp);
        emit TraitsChanged(tokenId, traits);
    }


    /// @notice Attempts to synchronize the frequency trait with an entangled pair.
    /// Success depends on coherence.
    /// @param tokenId The ID of one token in the pair.
    function synchronizeFrequency(uint256 tokenId) public onlyInteractionDelegate(tokenId) whenNotCollapsed(tokenId) {
        uint256 pairId = _entangledPair[tokenId];
        require(pairId != 0, "QENFT: Token is not entangled");
         require(_exists(tokenId), "QENFT: Token does not exist"); // Safety check

        _applyTimeBasedDynamics(tokenId);
        _applyTimeBasedDynamics(pairId);

        uint256 energyCost = 100; // Example cost
        _spendEnergy(tokenId, energyCost); // Only spend from one side for this action

        NFTTraits storage traits1 = _tokenTraits[tokenId];
        NFTTraits storage traits2 = _tokenTraits[pairId];

        uint256 randomness = _generateRandomness(tokenId + block.timestamp + 3);
        uint256 averageCoherence = (traits1.coherence + traits2.coherence) / 2;
        uint256 successChance = (syncSuccessProbability * averageCoherence) / MAX_COHERENCE; // Higher coherence = higher chance

        if (randomness % 1000 < successChance) {
            // Success: Frequencies synchronize, Coherence increases
            uint256 avgFreq = (traits1.frequency + traits2.frequency) / 2;
            traits1.frequency = avgFreq;
            traits2.frequency = avgFreq;
            traits1.coherence = Math.min(traits1.coherence + 20, MAX_COHERENCE);
            traits2.coherence = Math.min(traits2.coherence + 20, MAX_COHERENCE);
            // Stability might slightly decrease due to forced alignment
             traits1.stability = (traits1.stability > 5) ? traits1.stability - 5 : 0;
             traits2.stability = (traits2.stability > 5) ? traits2.stability - 5 : 0;

        } else {
            // Failure: Frequencies diverge, Coherence decreases
            traits1.frequency = (traits1.frequency + randomness % 20) % MAX_FREQUENCY; // Random small change
            traits2.frequency = (traits2.frequency + randomness % 25 + 5) % MAX_FREQUENCY; // Different random change
            traits1.coherence = (traits1.coherence > 10) ? traits1.coherence - 10 : 0;
            traits2.coherence = (traits2.coherence > 10) ? traits2.coherence - 10 : 0;
            // Stability might increase as they become more independent
             traits1.stability = Math.min(traits1.stability + 5, MAX_STABILITY);
             traits2.stability = Math.min(traits2.stability + 5, MAX_STABILITY);
        }

         _lastInteractionTime[tokenId] = uint64(block.timestamp);
         _lastInteractionTime[pairId] = uint64(block.timestamp); // Update both

        emit TraitsChanged(tokenId, traits1);
        emit TraitsChanged(pairId, traits2);
    }

    /// @notice Triggers a significant, potentially chaotic 'quantum fluctuation'.
    /// This drastically changes traits and potential state. High risk/reward.
    /// @param tokenId The ID of the token to fluctuate.
    function triggerQuantumFluctuation(uint256 tokenId) public payable onlyInteractionDelegate(tokenId) whenNotCollapsed(tokenId) {
         require(_exists(tokenId), "QENFT: Token does not exist");
         require(msg.value >= fluctuationCost, "QENFT: Insufficient fluctuation cost");

        _applyTimeBasedDynamics(tokenId);

        uint256 randomness = _generateRandomness(tokenId + block.timestamp + 4);
        NFTTraits storage traits = _tokenTraits[tokenId];

        // Drastic trait randomization
        traits.stability = randomness % MAX_STABILITY;
        traits.energy = Math.min(traits.energy + randomness % 200, MAX_ENERGY); // May gain or lose energy
        traits.frequency = randomness % MAX_FREQUENCY;
        traits.coherence = randomness % MAX_COHERENCE;
        traits.potentialState = PotentialState(randomness % 4); // Could land on any state, including Undetermined

        // Lower stability slightly as it's a chaotic event
        traits.stability = (traits.stability > 15) ? traits.stability - 15 : 0;

        emit QuantumFluctuationTriggered(tokenId);
        _applyEntanglementRipple(tokenId, randomness + 1); // Ripple effect

         _lastInteractionTime[tokenId] = uint64(block.timestamp);
        emit TraitsChanged(tokenId, traits);
    }

    /// @notice Attempts to permanently collapse the state of an NFT, making its traits static.
    /// Requires high stability and coherence. Irreversible.
    /// @param tokenId The ID of the token to collapse.
    function collapseState(uint256 tokenId) public payable onlyInteractionDelegate(tokenId) whenNotCollapsed(tokenId) {
         require(_exists(tokenId), "QENFT: Token does not exist");
         require(msg.value >= collapseCost, "QENFT: Insufficient collapse cost");

        _applyTimeBasedDynamics(tokenId);

        NFTTraits storage traits = _tokenTraits[tokenId];

        // Conditions for collapse (example: requires high stability and coherence)
        require(traits.stability >= MAX_STABILITY * 0.8, "QENFT: Stability too low for collapse");
        require(traits.coherence >= MAX_COHERENCE * 0.9, "QENFT: Coherence too low for collapse");
         require(traits.potentialState != PotentialState.Undetermined, "QENFT: Potential state is undetermined");


        // State is successfully collapsed
        _isStateCollapsed[tokenId] = true;

        // Finalize potentialState to currentState (example: lock into current potentialState)
        // Traits are now fixed at these values. Time-based dynamics and interactions will no longer affect them.
        // Entanglement does not prevent collapse, but a collapsed token no longer ripples effects or changes itself.

        emit StateCollapsed(tokenId);
        emit TraitsChanged(tokenId, traits); // Emit final static traits

        // Refund any excess Ether sent
        if (msg.value > collapseCost) {
            payable(msg.sender).transfer(msg.value - collapseCost);
        }
    }

    /// @notice Checks if the state of an NFT has been collapsed.
    /// @param tokenId The ID of the token.
    /// @return True if collapsed, false otherwise.
    function isStateCollapsed(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _isStateCollapsed[tokenId];
    }

    /// @notice Allows the owner to delegate interaction rights for their token to another address.
    /// @param tokenId The ID of the token.
    /// @param delegate The address to delegate rights to.
    /// @param duration The duration in seconds for which rights are delegated.
    function delegateInteraction(uint256 tokenId, address delegate, uint64 duration) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QENFT: Caller is not owner or approved");
        require(delegate != address(0), "QENFT: Invalid delegate address");

        uint64 expiration = uint64(block.timestamp) + duration;
        _interactionDelegates[tokenId][delegate] = expiration;

        emit InteractionDelegated(tokenId, delegate, expiration);
    }

    /// @notice Revokes interaction rights from a delegate.
    /// @param tokenId The ID of the token.
    /// @param delegate The address whose rights to revoke.
    function revokeInteraction(uint256 tokenId, address delegate) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QENFT: Caller is not owner or approved");
         require(delegate != address(0), "QENFT: Invalid delegate address");

        delete _interactionDelegates[tokenId][delegate];

        emit InteractionRevoked(tokenId, delegate);
    }

    /// @notice Checks if an address has interaction rights for a token and returns expiration time.
    /// @param tokenId The ID of the token.
    /// @param delegate The address to check.
    /// @return The expiration timestamp of the delegation, or 0 if not delegated or expired.
    function checkInteractionDelegate(uint256 tokenId, address delegate) public view returns (uint64) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        uint64 expiration = _interactionDelegates[tokenId][delegate];
        if (expiration > block.timestamp) {
            return expiration;
        }
        return 0;
    }

     /// @notice Gets the timestamp of the last recorded interaction for a token.
     /// Useful for checking time-based dynamics progress off-chain.
     /// @param tokenId The ID of the token.
     /// @return The timestamp of the last interaction.
    function getLastInteractionTime(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "QENFT: Token does not exist");
        return _lastInteractionTime[tokenId];
    }

    // --- Admin Functions (Owner Only) ---

    /// @notice Sets the cost in Wei to entangle two NFTs.
    /// @param cost The new entanglement cost in Wei.
    function setEntanglementCost(uint256 cost) public onlyOwner {
        entanglementCost = uint224(cost);
    }

    /// @notice Sets the cost in Wei to trigger quantum fluctuation.
    /// @param cost The new fluctuation cost in Wei.
    function setFluctuationCost(uint256 cost) public onlyOwner {
        fluctuationCost = uint224(cost);
    }

     /// @notice Sets the cost in Wei to collapse the state of an NFT.
    /// @param cost The new collapse cost in Wei.
    function setCollapseCost(uint256 cost) public onlyOwner {
        collapseCost = uint224(cost);
    }

    /// @notice Sets the decay rates for various traits per hour (scaled by 100).
    /// @param _energyDecay The new energy decay rate.
    /// @param _coherenceDecay The new coherence decay rate.
    /// @param _stabilityDecay The new stability decay rate.
    function setDecayRates(uint256 _energyDecay, uint256 _coherenceDecay, uint256 _stabilityDecay) public onlyOwner {
        energyDecayRatePerHour = _energyDecay;
        coherenceDecayRatePerHour = _coherenceDecay;
        stabilityDecayRatePerHour = _stabilityDecay;
    }

     /// @notice Sets the regeneration rates for various traits per hour (scaled by 100).
     /// @param _energyRegen The new energy regeneration rate.
     /// @param _coherenceRegen The new coherence regeneration rate.
    function setRegenerationRates(uint256 _energyRegen, uint256 _coherenceRegen) public onlyOwner {
        energyRegenRatePerHour = _energyRegen;
        coherenceRegenRatePerHour = _coherenceRegen;
    }

    /// @notice Sets the probabilities for various outcomes (scaled by 1000).
    /// @param _syncSuccessProb The new sync success probability (out of 1000).
    /// @param _fluctuationProb The new quantum fluctuation probability (out of 1000, checked on interaction).
    /// @param _rippleProb The new entanglement ripple probability (out of 1000).
    function setProbabilities(uint256 _syncSuccessProb, uint256 _fluctuationProb, uint256 _rippleProb) public onlyOwner {
        require(_syncSuccessProb <= 1000 && _fluctuationProb <= 1000 && _rippleProb <= 1000, "QENFT: Probabilities out of range (0-1000)");
        syncSuccessProbability = _syncSuccessProb;
        fluctuationProbability = _fluctuationProb;
        entanglementRippleProbability = _rippleProb;
    }


    /// @notice Allows the contract owner to withdraw collected Ether fees.
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "QENFT: No fees to withdraw");
        payable(owner()).transfer(balance);
    }

    // The following functions are overrides required by Solidity.
    // They mostly just call the super implementation but are needed
    // because this contract inherits from multiple OpenZeppelin extensions.

    // No need to list all inherited ERC721 functions in the summary if the
    // focus is on *custom, creative* functions, but they are part of the contract.
    // e.g., ownerOf, balanceOf, transferFrom, approve, etc.
}
```