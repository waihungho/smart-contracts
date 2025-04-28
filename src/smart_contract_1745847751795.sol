Okay, this is an exciting challenge! Let's create a smart contract concept that simulates aspects of quantum mechanics applied to NFTs. We'll call it "Quantum Entanglement NFTs".

The idea is that these NFTs can be "entangled" with each other. Observing (interacting with) one entangled NFT might instantaneously affect the state of its entangled partner, possibly probabilistically. We can add concepts like superposition (a temporary state of uncertainty), decoherence (breaking entanglement), and decay. We'll also introduce "Catalyst" tokens within the contract that can influence the probabilities.

This is *not* real quantum computing, but an *analogy* implemented on a classical blockchain, focusing on unique state transitions and interactions.

---

**Contract Concept:** `QuantumEntanglementNFT`

**Analogy:** Simulating quantum-like behaviors (Entanglement, Superposition, Observation/Collapse, Decoherence, Decay) on NFTs.

**Key Features:**

1.  **NFT States:** NFTs can exist in different abstract "quantum states".
2.  **Entanglement:** Two NFTs can be programmatically entangled, linking their fates during "observation".
3.  **Observation:** A specific action on an entangled NFT that can probabilistically alter its state and potentially the state of its entangled partner.
4.  **Decoherence:** The process of breaking the entanglement link.
5.  **Superposition (Simulated):** A temporary state or flag indicating potential for multiple outcomes before observation.
6.  **Decay:** NFTs can probabilistically decay over time or interactions, reaching a terminal state.
7.  **Catalyst Tokens:** A fungible token (internal to the contract) that can be used to influence the probabilities of state changes during observation.

**Limitations:**

*   **Randomness:** True quantum randomness is impossible on-chain. We will use pseudo-randomness based on block data, which is NOT secure for high-value probabilistic outcomes against determined adversaries (miners). A Chainlink VRF integration would be required for secure randomness, but adds complexity and external dependency, so we'll use block data for this example contract.
*   **"Instantaneous" Effect:** On a blockchain, "instantaneous" means within the same transaction or block, not truly outside of spacetime.
*   **Analogy Only:** This is a creative *simulation* of quantum concepts, not a literal implementation.

---

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary libraries (ERC-721, Ownable, Pausable, ReentrancyGuard).
2.  **Error Handling:** Define custom errors.
3.  **State Variables:**
    *   ERC721 standard mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`, `_tokenURIs`, `_baseURI`).
    *   Token specific data (`_tokenState`, `_isEntangled`, `_entangledPartner`, `_lastObservationTime`, `_entanglementTime`).
    *   Catalyst token data (`_catalystBalances`, `_catalystAllowances`, `_totalCatalystSupply`).
    *   Probabilities and intervals (`_observationProbability`, `_entanglementDecayProbability`, `_decayInterval`, `_stateTransitionProbabilities` - potentially complex, maybe simplify).
    *   Admin settings (`_maxSupply`, `_catalystMintAmount`).
    *   Randomness nonce.
4.  **Enums:** Define possible `NFTState` types.
5.  **Events:** Define events for significant actions (Mint, Transfer, Entangle, Decoherence, StateChange, Observation, Decay, CatalystMint, CatalystTransfer, CatalystUse).
6.  **Constructor:** Initialize contract owner, name, symbol, and initial settings.
7.  **Modifiers:** Custom modifiers for state checks (`notDecayed`, `onlyEntangled`, `notEntangled`, `whenEntangledAndPartnerValid`).
8.  **Internal Helper Functions:**
    *   `_generatePseudoRandomFactor()`: Generate pseudo-randomness.
    *   `_applyObservationEffect()`: Core logic for state changes based on observation, entanglement, randomness, and catalysts.
    *   `_decayCheck()`: Internal check for potential decay based on time.
    *   `_updateEntanglement()`: Helper to link two tokens as entangled partners.
    *   `_clearEntanglement()`: Helper to break the entanglement link.
    *   `_performStateTransition()`: Helper to change a token's state and emit event.
9.  **ERC-721 Implementation (Overrides and Customizations):**
    *   `supportsInterface()`
    *   `balanceOf()`
    *   `ownerOf()`
    *   `safeTransferFrom()`, `transferFrom()` (Override to potentially handle entanglement)
    *   `approve()`, `setApprovalForAll()`, `getApproved()`, `isApprovedForAll()`
    *   `tokenURI()` (Custom logic to potentially reflect state in metadata URI)
    *   `_beforeTokenTransfer()` (Custom logic)
    *   `mint()`: Custom minting, setting initial state and tracking.
    *   `burn()`: Custom burning, clearing state and tracking.
10. **Quantum/Concept Functions (20+ total, including ERC721):**
    *   `entangle(tokenId1, tokenId2)`: Entangle two NFTs.
    *   `decohre(tokenId)`: Break entanglement.
    *   `observe(tokenId)`: Trigger observation, state change logic.
    *   `decayState(tokenId)`: Manually trigger decay check (or integrate into `observe`).
    *   `useCatalyst(tokenId, amount)`: Consume catalyst to influence observation.
11. **Catalyst Token Functions (Fungible, internal to contract):**
    *   `mintCatalyst()`: Allow users/owner to mint catalyst tokens (with limits).
    *   `transferCatalyst(to, amount)`: Transfer catalyst tokens.
    *   `approveCatalyst(spender, amount)`: Approve spender for catalyst.
    *   `allowanceCatalyst(owner, spender)`: Check catalyst allowance.
    *   `burnCatalyst(amount)`: Burn catalyst tokens.
12. **Query Functions (Getters):**
    *   `getTokenState(tokenId)`
    *   `getEntangledToken(tokenId)`
    *   `isEntangled(tokenId)`
    *   `getLastObservationTime(tokenId)`
    *   `getEntanglementTime(tokenId)`
    *   `getCatalystBalance(owner)`
    *   `getCatalystAllowance(owner, spender)`
    *   `getTotalCatalystSupply()`
    *   `getMaxSupply()`
    *   `getCurrentSupply()` (or just use `totalSupply` from ERC721)
    *   `getDecayInterval()`
    *   `getObservationProbability()`
    *   `getEntanglementDecayProbability()`
    *   `getStateTransitionProbability(fromState, toState)` (if probabilities are granular)
13. **Admin Functions (Owner-only):**
    *   `pause()`, `unpause()`
    *   `withdrawEth()` (If contract collects any ETH)
    *   `setMaxSupply(supply)`
    *   `setCatalystMintAmount(amount)`
    *   `setDecayInterval(interval)`
    *   `setObservationProbabilities(...)` (Functions to adjust probabilities)
    *   `setEntanglementDecayProbability(prob)`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title QuantumEntanglementNFT
/// @dev An NFT contract simulating quantum-like entanglement and state changes.
/// @dev NFTs can be entangled. Observing one entangled NFT may affect its partner probabilistically.
/// @dev Includes concepts like decay and internal catalyst tokens to influence probabilities.
/// @dev NOTE: Pseudorandomness is used based on block data, which is NOT cryptographically secure.
/// @dev For production use requiring secure randomness, integrate a solution like Chainlink VRF.

contract QuantumEntanglementNFT is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Outline & Function Summary ---
    // 1. State Variables & Constants: Define contract storage and parameters.
    // 2. Enums: Define possible NFT states.
    // 3. Errors: Custom error types.
    // 4. Events: Announce key contract actions.
    // 5. Modifiers: Custom access and state condition checks.
    // 6. Internal Helpers: Core logic functions used internally.
    // 7. Constructor: Initialize contract.
    // 8. ERC-721 Core Functionality (Overrides):
    //    - supportsInterface: Required for ERC-165.
    //    - ownerOf: Get token owner.
    //    - balanceOf: Get owner's token count.
    //    - getApproved: Get approved address for a token.
    //    - isApprovedForAll: Check if operator is approved.
    //    - approve: Approve address for a token.
    //    - setApprovalForAll: Set operator approval.
    //    - transferFrom: Transfer token, checks and updates state.
    //    - safeTransferFrom (x2 overloads): Safe transfer, checks and updates state.
    //    - tokenURI: Get metadata URI (potentially dynamic based on state).
    //    - _beforeTokenTransfer: Internal hook for transfer logic.
    // 9. NFT Lifecycle & State Management:
    //    - mint: Create a new NFT, set initial state.
    //    - burn: Destroy an NFT, clear state.
    //    - getTokenState: Get current state of an NFT.
    //    - getLastObservationTime: Get timestamp of last observation.
    //    - getEntanglementTime: Get timestamp of entanglement.
    // 10. Entanglement Functions:
    //    - entangle: Link two NFTs into an entangled pair.
    //    - decohre: Break the entanglement link for a token pair.
    //    - getEntangledToken: Get the entangled partner ID.
    //    - isEntangled: Check if a token is entangled.
    // 11. Quantum Interaction (Observation):
    //    - observe: Trigger observation on an NFT, potentially changing states of the token and its partner.
    // 12. Decay Functions:
    //    - decayState: Trigger a check and potential transition to Decayed state.
    //    - getDecayInterval: Get the time interval threshold for decay checks.
    // 13. Catalyst Token Management:
    //    - mintCatalyst: Mint Catalyst tokens for the caller.
    //    - transferCatalyst: Transfer Catalyst tokens.
    //    - approveCatalyst: Approve spender for Catalyst tokens.
    //    - allowanceCatalyst: Get Catalyst allowance.
    //    - useCatalyst: Consume Catalyst tokens to influence observation outcomes.
    //    - burnCatalyst: Burn Catalyst tokens.
    //    - getCatalystBalance: Get Catalyst token balance for an address.
    //    - getCatalystAllowance: Get Catalyst allowance for a spender.
    //    - getTotalCatalystSupply: Get total minted Catalyst tokens.
    // 14. Admin Functions (Owner-only):
    //    - pause: Pause key contract functions.
    //    - unpause: Unpause contract functions.
    //    - withdrawEth: Withdraw accidental ETH sent to contract.
    //    - setBaseURI: Set the base URI for token metadata.
    //    - setMaxSupply: Set the maximum number of NFTs that can be minted.
    //    - setCatalystMintAmount: Set the amount of Catalyst minted per call.
    //    - setDecayInterval: Set the minimum time between decay checks.
    //    - setObservationProbabilities: Adjust probabilities for state transitions during observation.
    //    - setEntanglementDecayProbability: Adjust probability of entanglement breaking during observation.
    //    - setCatalystEffectMultiplier: Adjust how much catalyst influences probabilities.
    // 15. Getters (General):
    //    - getMaxSupply: Get the maximum token supply.
    //    - getCurrentSupply: Get the current number of minted tokens.

    // --- State Variables & Constants ---

    // NFT Data
    enum NFTState {
        Initial,    // Starting state
        Superposed, // State of potential/uncertainty (simulated)
        StateA,     // A stable observed state
        StateB,     // Another stable observed state
        StateC,     // Yet another stable observed state
        Decayed     // Terminal state, unusable
    }
    mapping(uint256 => NFTState) private _tokenState;
    mapping(uint256 => uint256) private _entangledPartner; // 0 if not entangled
    mapping(uint256 => uint256) private _lastObservationTime; // Timestamp
    mapping(uint256 => uint256) private _entanglementTime; // Timestamp when entangled
    mapping(uint256 => bool) private _isDecayed;

    // Catalyst Token Data (Fungible, Internal)
    mapping(address => uint256) private _catalystBalances;
    mapping(address => mapping(address => uint256)) private _catalystAllowances;
    uint256 private _totalCatalystSupply;
    uint256 private _catalystMintAmount = 100; // Default amount of catalyst minted per call

    // Probabilities & Settings (Stored as basis points, 10000 = 100%)
    uint256 private _observationProbabilityBasisPoints = 8000; // 80% chance of state change on observe if not decayed
    uint256 private _entanglementDecayProbabilityBasisPoints = 1000; // 10% chance entanglement breaks on observe
    uint256 private _decayProbabilityBasisPoints = 500; // 5% chance of decay on observe if past decay interval
    uint256 private _decayInterval = 30 days; // Time in seconds after which decay is checked
    uint256 private _catalystEffectMultiplier = 100; // 100 basis points = 1x influence

    // State transition probabilities (simplified: equal chance between non-decayed states)
    // For a more complex system, use mapping((NFTState, NFTState) => uint256) probabilities

    uint256 private _maxSupply;
    uint256 private _randomnessNonce = 0; // To ensure unique pseudo-random values

    // --- Errors ---
    error EntanglementFailed(string reason);
    error DecoherenceFailed(string reason);
    error ObservationFailed(string reason);
    error CatalystUseFailed(string reason);
    error DecayFailed(string reason);
    error InvalidTokenState(uint256 tokenId, NFTState currentState);
    error TokenAlreadyExists(uint256 tokenId); // Should not happen with Counters
    error TokenDoesNotExist(uint256 tokenId);
    error MaxSupplyReached();
    error NotEnoughCatalyst(uint256 required, uint256 has);
    error AllowanceExceeded(uint256 required, uint256 allowed);
    error NotEntangled(uint256 tokenId);
    error AlreadyEntangled(uint256 tokenId);
    error CannotEntangleWithSelf();
    error TokenDecayed(uint256 tokenId);
    error ProbabilityOutOfRange();

    // --- Events ---
    event NFTMinted(address indexed owner, uint256 indexed tokenId, NFTState initialState);
    event NFTBurned(uint256 indexed tokenId);
    event NFTStateChanged(uint256 indexed tokenId, NFTState oldState, NFTState newState, string reason);
    event NFTEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 entanglementTime);
    event NFTDecohered(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event NFTObserved(uint256 indexed tokenId, uint256 randomFactor, uint256 catalystsUsed);
    event NFTDecayed(uint256 indexed tokenId, uint256 decayTime);
    event CatalystMinted(address indexed receiver, uint256 amount, uint256 totalCatalystSupply);
    event CatalystTransferred(address indexed from, address indexed to, uint256 amount);
    event CatalystApproved(address indexed owner, address indexed spender, uint256 amount);
    event CatalystUsed(uint256 indexed tokenId, address indexed user, uint256 amount);
    event CatalystBurned(address indexed burner, uint256 amount, uint256 totalCatalystSupply);

    // --- Modifiers ---
    modifier notDecayed(uint256 tokenId) {
        if (_isDecayed[tokenId]) {
            revert TokenDecayed(tokenId);
        }
        _;
    }

    modifier onlyEntangled(uint256 tokenId) {
        if (_entangledPartner[tokenId] == 0) {
            revert NotEntangled(tokenId);
        }
        _;
    }

    modifier notEntangled(uint256 tokenId) {
        if (_entangledPartner[tokenId] != 0) {
            revert AlreadyEntangled(tokenId);
        }
        _;
    }

    modifier whenEntangledAndPartnerValid(uint256 tokenId) {
        uint256 partnerId = _entangledPartner[tokenId];
        if (partnerId == 0 || _owners[partnerId] == address(0) || _isDecayed[partnerId]) {
            // Automatically decohere if partner is invalid or decayed
            _clearEntanglement(tokenId, partnerId, "Partner invalid or decayed");
            revert EntanglementFailed("Partner invalid or decayed"); // Or allow the action after decoherence? Let's revert for safety.
        }
        _;
    }

    // --- Internal Helper Functions ---

    /// @dev Generates a pseudo-random factor. NOT cryptographically secure.
    /// @return A pseudo-random uint256.
    function _generatePseudoRandomFactor() internal returns (uint256) {
        _randomnessNonce++;
        // Using block.timestamp, block.difficulty, msg.sender, and a nonce for basic pseudo-randomness
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _randomnessNonce, block.number)));
        return randomFactor;
    }

    /// @dev Applies state change logic based on observation, entanglement, randomness, and catalysts.
    /// @param tokenId The ID of the token being observed.
    /// @param randomFactor The pseudo-random value for this observation.
    /// @param catalystsUsed The amount of catalyst tokens used in this observation.
    function _applyObservationEffect(uint256 tokenId, uint256 randomFactor, uint256 catalystsUsed) internal notDecayed(tokenId) {
        NFTState currentState = _tokenState[tokenId];
        uint256 partnerId = _entangledPartner[tokenId];
        bool isEntangled = (partnerId != 0);

        // Apply decay check before state change
        _decayCheck(tokenId, randomFactor);
        if (_isDecayed[tokenId]) {
            emit ObservationFailed("Token decayed during decay check"); // Should not happen due to modifier, but safety
            return; // Exit if decayed
        }

        // Determine effective probability basis points influenced by catalysts
        uint256 effectiveObsProb = _observationProbabilityBasisPoints;
        // Simple catalyst effect: each catalyst adds 1 basis point to probability (multiplied by multiplier)
        effectiveObsProb = Math.min(10000, effectiveObsProb + (catalystsUsed * _catalystEffectMultiplier));

        // Check if a state change happens
        if (randomFactor % 10000 < effectiveObsProb) {
            NFTState nextState = currentState;
            // Determine the next state probabilistically (simple: cycle through non-decayed states)
            uint256 stateCount = uint256(NFTState.Decayed); // Number of non-decayed states + Decayed
            uint256 currentStateIndex = uint256(currentState);

            // Simple next state logic: cycle through non-decayed states
            uint256 nextStateIndex = (currentStateIndex + (randomFactor / 10000) % (stateCount - 1)) % (stateCount - 1); // Cycle 0 -> 1 -> 2 -> 3 -> 0 ...
            if (nextStateIndex == 0) nextState = NFTState.Initial; // Ensure mapping back to enum
            else if (nextStateIndex == 1) nextState = NFTState.Superposed;
            else if (nextStateIndex == 2) nextState = NFTState.StateA;
            else if (nextStateIndex == 3) nextState = NFTState.StateB;
            else if (nextStateIndex == 4) nextState = NFTState.StateC;


            // Ensure next state is not Decayed unless explicitly decaying
             if (nextState != NFTState.Decayed) {
                _performStateTransition(tokenId, nextState, "Observed");

                // Quantum Entanglement Effect: Affect partner if entangled
                if (isEntangled) {
                     _decayCheck(partnerId, randomFactor); // Check partner for decay first
                     if (!_isDecayed[partnerId]) {
                        // Simple effect: partner also transitions to the SAME state probabilistically
                        // Or, could have a linked transition table: StateA on token1 -> StateB on token2
                        // Let's keep it simple: partner also transitions to the new state based on a linked probability or randomness
                        // For this example, let's say entangled partners have a high chance to transition to the *same* state
                         if ((randomFactor / 100) % 100 < 90) { // 90% chance partner adopts the same state
                              _performStateTransition(partnerId, nextState, "Entanglement effect from observation");
                         } else {
                             // Small chance partner transitions to a different random state
                             uint256 partnerNextStateIndex = (uint256(_tokenState[partnerId]) + (randomFactor / 50) % (stateCount - 1)) % (stateCount - 1); // Different random calculation
                              if (partnerNextStateIndex == 0) _performStateTransition(partnerId, NFTState.Initial, "Entanglement effect (divergent)");
                              else if (partnerNextStateIndex == 1) _performStateTransition(partnerId, NFTState.Superposed, "Entanglement effect (divergent)");
                              else if (partnerNextStateIndex == 2) _performStateTransition(partnerId, NFTState.StateA, "Entanglement effect (divergent)");
                              else if (partnerNextStateIndex == 3) _performStateTransition(partnerId, NFTState.StateB, "Entanglement effect (divergent)");
                              else if (partnerNextStateIndex == 4) _performStateTransition(partnerId, NFTState.StateC, "Entanglement effect (divergent)");
                         }
                     } else {
                         // Partner decayed, entanglement breaks
                          _clearEntanglement(tokenId, partnerId, "Partner decayed");
                     }
                }
             }
        }

        // Probabilistic Entanglement Decay (Decoherence) on Observation
        if (isEntangled && (randomFactor / 10000) % 10000 < _entanglementDecayProbabilityBasisPoints) {
             _clearEntanglement(tokenId, partnerId, "Probabilistic decay during observation");
        }

        _lastObservationTime[tokenId] = block.timestamp;
         if (isEntangled) {
             _lastObservationTime[partnerId] = block.timestamp; // Update partner's observation time too
         }
    }


    /// @dev Internal function to check and potentially transition an NFT to the Decayed state.
    /// @param tokenId The ID of the token to check.
    /// @param randomFactor A random factor to use for the probability check.
    function _decayCheck(uint256 tokenId, uint256 randomFactor) internal {
         if (_isDecayed[tokenId]) {
            return; // Already decayed
         }

         bool pastDecayInterval = (block.timestamp - _lastObservationTime[tokenId] >= _decayInterval);

         if (pastDecayInterval) {
             // Apply decay probability
             if ((randomFactor / 100) % 10000 < _decayProbabilityBasisPoints) {
                 _performStateTransition(tokenId, NFTState.Decayed, "Decayed over time");
                 _isDecayed[tokenId] = true;
                 emit NFTDecayed(tokenId, block.timestamp);

                 uint256 partnerId = _entangledPartner[tokenId];
                 if (partnerId != 0) {
                    _clearEntanglement(tokenId, partnerId, "Decayed token");
                 }
             }
         }
    }

    /// @dev Internal helper to update entanglement mapping bidirectionally.
    function _updateEntanglement(uint256 tokenId1, uint256 tokenId2) internal {
         _entangledPartner[tokenId1] = tokenId2;
         _entangledPartner[tokenId2] = tokenId1;
         _entanglementTime[tokenId1] = block.timestamp;
         _entanglementTime[tokenId2] = block.timestamp;
    }

    /// @dev Internal helper to clear entanglement mapping bidirectionally.
    function _clearEntanglement(uint256 tokenId1, uint256 tokenId2, string memory reason) internal {
        if (_entangledPartner[tokenId1] == tokenId2 && _entangledPartner[tokenId2] == tokenId1) {
            delete _entangledPartner[tokenId1];
            delete _entangledPartner[tokenId2];
            delete _entanglementTime[tokenId1];
            delete _entanglementTime[tokenId2];
            emit NFTDecohered(tokenId1, tokenId2);
            emit NFTStateChanged(tokenId1, _tokenState[tokenId1], _tokenState[tokenId1], string(abi.encodePacked("Decohered: ", reason)));
            emit NFTStateChanged(tokenId2, _tokenState[tokenId2], _tokenState[tokenId2], string(abi.encodePacked("Decohered: ", reason)));
        } else {
            // Handle potential inconsistent state if needed, though _entangledPartner == partner check should prevent this
            // For now, assume consistent state due to _updateEntanglement
        }
    }

     /// @dev Internal helper to perform a state transition and emit the event.
     /// @param tokenId The ID of the token.
     /// @param newState The new state to transition to.
     /// @param reason The reason for the state change.
     function _performStateTransition(uint256 tokenId, NFTState newState, string memory reason) internal {
         NFTState oldState = _tokenState[tokenId];
         if (oldState != newState) {
             _tokenState[tokenId] = newState;
             emit NFTStateChanged(tokenId, oldState, newState, reason);
         }
     }


    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable(false) // Start unpaused
    {}

    // --- ERC-721 Core Functionality (Overrides and Customizations) ---

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // Standard ERC721 getters
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId); // Uses OpenZeppelin's internal _owners
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner); // Uses OpenZeppelin's internal _balances
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId); // Uses OpenZeppelin's internal _tokenApprovals
    }

     function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator); // Uses OpenZeppelin's internal _operatorApprovals
    }

    // Standard ERC721 setters (override to use Pausable)
     function approve(address to, uint256 tokenId) public override notDecayed(tokenId) whenNotPaused {
        super.approve(to, tokenId);
     }

     function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        super.setApprovalForAll(operator, approved);
     }


    /// @dev Overrides transferFrom to include custom checks (like decay) and hooks.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override notDecayed(tokenId) whenNotPaused {
        // _beforeTokenTransfer hook is called by super.transferFrom
        super.transferFrom(from, to, tokenId);
        // No change to entanglement or state on transfer by default, new owner controls.
        // Could add logic here: e.g., transfers break entanglement
        // If decided transfers break entanglement:
        // uint256 partnerId = _entangledPartner[tokenId];
        // if (partnerId != 0) {
        //    _clearEntanglement(tokenId, partnerId, "Transfer breaks entanglement");
        // }
    }

    /// @dev Overrides safeTransferFrom to include custom checks (like decay) and hooks.
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override notDecayed(tokenId) whenNotPaused {
         // _beforeTokenTransfer hook is called by super.safeTransferFrom
        super.safeTransferFrom(from, to, tokenId);
         // If decided transfers break entanglement:
        // uint256 partnerId = _entangledPartner[tokenId];
        // if (partnerId != 0) {
        //    _clearEntanglement(tokenId, partnerId, "Transfer breaks entanglement");
        // }
    }

    /// @dev Overrides safeTransferFrom to include custom checks (like decay) and hooks.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override notDecayed(tokenId) whenNotPaused {
        // _beforeTokenTransfer hook is called by super.safeTransferFrom
        super.safeTransferFrom(from, to, tokenId, data);
         // If decided transfers break entanglement:
        // uint256 partnerId = _entangledPartner[tokenId];
        // if (partnerId != 0) {
        //    _clearEntanglement(tokenId, partnerId, "Transfer breaks entanglement");
        // }
    }

    /// @dev Internal hook called before any token transfer.
    /// @param from The address sending the token (address(0) for mint).
    /// @param to The address receiving the token (address(0) for burn).
    /// @param tokenId The ID of the token being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) { // Minting
            // Set initial state during mint
            _tokenState[tokenId] = NFTState.Initial;
            _lastObservationTime[tokenId] = block.timestamp; // Set initial observation time
            _isDecayed[tokenId] = false; // Ensure not decayed
            emit NFTMinted(to, tokenId, NFTState.Initial);

        } else if (to == address(0)) { // Burning
             // Clear state and entanglement on burn
             uint256 partnerId = _entangledPartner[tokenId];
             if (partnerId != 0) {
                _clearEntanglement(tokenId, partnerId, "Burned token");
             }
             delete _tokenState[tokenId];
             delete _lastObservationTime[tokenId];
             delete _entanglementTime[tokenId];
             delete _isDecayed[tokenId]; // Clear decay status
             emit NFTBurned(tokenId);
        } else { // Transferring
            // Decay check on transfer? (Optional)
            // uint256 randomFactor = _generatePseudoRandomFactor();
            // _decayCheck(tokenId, randomFactor);
            // if (_isDecayed[tokenId]) {
            //    revert TransferFailed("Token decayed during transfer check"); // Example
            // }
        }
    }


    /// @dev Returns the URI for the metadata of a token.
    /// @param tokenId The ID of the token.
    /// @return The URI string.
    function tokenURI(uint256 tokenId) public view override notDecayed(tokenId) returns (string memory) {
        // Check if token exists
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        // Build metadata URI based on state (Example: Append state to base URI)
        string memory base = _baseURI();
        string memory stateString = "";
        NFTState currentState = _tokenState[tokenId];
        if (currentState == NFTState.Initial) stateString = "initial";
        else if (currentState == NFTState.Superposed) stateString = "superposed";
        else if (currentState == NFTState.StateA) stateString = "stateA";
        else if (currentState == NFTState.StateB) stateString = "stateB";
        else if (currentState == NFTState.StateC) stateString = "stateC";
        else if (currentState == NFTState.Decayed) stateString = "decayed"; // Should be caught by notDecayed modifier but safety

        return string(abi.encodePacked(base, Strings.toString(tokenId), "-", stateString, ".json"));
    }

    /// @dev Gets the base URI for token metadata.
    function _baseURI() internal view override returns (string memory) {
         return _tokenURIs[0]; // Using index 0 for the base URI string
    }

     /// @dev Sets the base URI for token metadata (owner only).
     /// @param newURI The new base URI.
     function setBaseURI(string memory newURI) public onlyOwner {
        _tokenURIs[0] = newURI;
     }


    // --- NFT Lifecycle & State Management ---

    /// @dev Mints a new NFT, assigning an initial state.
    /// @param to The address to mint the token to.
    /// @return The ID of the newly minted token.
    function mint(address to) public onlyOwner nonReentrant whenNotPaused returns (uint256) {
        if (_tokenIdCounter.current() >= _maxSupply && _maxSupply != 0) {
            revert MaxSupplyReached();
        }
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId); // Calls _beforeTokenTransfer internally

        // Initial state and timestamps are set in _beforeTokenTransfer

        return newTokenId;
    }

    /// @dev Burns an NFT.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) public virtual notDecayed(tokenId) whenNotPaused {
         address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert ERC721InsufficientApproval(msg.sender, tokenId);
        }
        _burn(tokenId); // Calls _beforeTokenTransfer internally
        // State, entanglement, timestamps cleared in _beforeTokenTransfer
    }

    /// @dev Gets the current quantum state of an NFT.
    /// @param tokenId The ID of the token.
    /// @return The NFTState enum value.
    function getTokenState(uint256 tokenId) public view returns (NFTState) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenState[tokenId];
    }

     /// @dev Gets the timestamp of the last observation for a token.
     /// @param tokenId The ID of the token.
     /// @return The timestamp.
     function getLastObservationTime(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _lastObservationTime[tokenId];
     }

     /// @dev Gets the timestamp when the token was last entangled.
     /// @param tokenId The ID of the token.
     /// @return The timestamp. Returns 0 if never entangled or currently not entangled.
     function getEntanglementTime(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _entanglementTime[tokenId];
     }


    // --- Entanglement Functions ---

    /// @dev Entangles two NFTs. Requires ownership or approval for both.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function entangle(uint256 tokenId1, uint256 tokenId2) public nonReentrant whenNotPaused {
        if (!_exists(tokenId1)) revert TokenDoesNotExist(tokenId1);
        if (!_exists(tokenId2)) revert TokenDoesNotExist(tokenId2);
        if (tokenId1 == tokenId2) revert CannotEntangleWithSelf();

        if (_isDecayed[tokenId1]) revert TokenDecayed(tokenId1);
        if (_isDecayed[tokenId2]) revert TokenDecayed(tokenId2);

        if (_entangledPartner[tokenId1] != 0) revert AlreadyEntangled(tokenId1);
        if (_entangledPartner[tokenId2] != 0) revert AlreadyEntangled(tokenId2);

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Check ownership or approval for tokenId1
        if (msg.sender != owner1 && !isApprovedForAll(owner1, msg.sender) && getApproved(tokenId1) != msg.sender) {
            revert EntanglementFailed("Caller not authorized for token1");
        }
         // Check ownership or approval for tokenId2
        if (msg.sender != owner2 && !isApprovedForAll(owner2, msg.sender) && getApproved(tokenId2) != msg.sender) {
             revert EntanglementFailed("Caller not authorized for token2");
        }

        _updateEntanglement(tokenId1, tokenId2);
        emit NFTEntangled(tokenId1, tokenId2, block.timestamp);

        // Maybe move to Superposed state upon entanglement?
        _performStateTransition(tokenId1, NFTState.Superposed, "Entangled");
        _performStateTransition(tokenId2, NFTState.Superposed, "Entangled");

    }

    /// @dev Breaks the entanglement link for a token and its partner.
    /// @param tokenId The ID of one of the entangled tokens.
    function decohre(uint256 tokenId) public notDecayed(tokenId) onlyEntangled(tokenId) nonReentrant whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert DecoherenceFailed("Caller not authorized for token");
        }

        uint256 partnerId = _entangledPartner[tokenId];
        // Check partner validity
         if (!_exists(partnerId) || _isDecayed[partnerId]) {
             _clearEntanglement(tokenId, partnerId, "Partner invalid or decayed during decoherence attempt");
             revert DecoherenceFailed("Partner token invalid or decayed"); // Revert after clearing state
         }

        _clearEntanglement(tokenId, partnerId, "Manual decoherence");

        // Move from Superposed back to a stable state upon decoherence?
         uint256 randomFactor = _generatePseudoRandomFactor();
         // Simple transition: 50% chance to Initial, 50% chance to StateA
         if (randomFactor % 100 < 50) {
              _performStateTransition(tokenId, NFTState.Initial, "Decohered");
              _performStateTransition(partnerId, NFTState.Initial, "Decohered");
         } else {
             _performStateTransition(tokenId, NFTState.StateA, "Decohered");
             _performStateTransition(partnerId, NFTState.StateA, "Decohered");
         }

    }

    /// @dev Gets the entangled partner ID for a token. Returns 0 if not entangled.
    /// @param tokenId The ID of the token.
    /// @return The partner token ID, or 0.
    function getEntangledToken(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0; // Token must exist
        return _entangledPartner[tokenId];
    }

    /// @dev Checks if a token is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return getEntangledToken(tokenId) != 0;
    }


    // --- Quantum Interaction (Observation) ---

    /// @dev Observes an NFT, potentially triggering state changes based on randomness, entanglement, and catalysts.
    /// @param tokenId The ID of the token to observe.
    function observe(uint256 tokenId) public nonReentrant whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        if (_isDecayed[tokenId]) revert TokenDecayed(tokenId);

        address owner = ownerOf(tokenId);
        // Allow owner or approved to observe
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert ObservationFailed("Caller not authorized for token");
        }

        uint256 randomFactor = _generatePseudoRandomFactor();

        // Catalyst logic: check if caller has approved catalyst use for themselves or the contract
        // This version is simple: caller consumes their *own* catalyst balance directly.
        // A more complex version would check allowances if the contract needs to spend someone else's catalyst.
        // Let's allow calling observe() with 0 catalyst and use useCatalyst() separately first.
        // Or, modify observe to take catalyst amount as parameter: observe(tokenId, catalystAmount)

        // Let's make observe simple (uses 0 catalysts directly) and have a separate useCatalyst function that influences the *next* observe.
        // Or, allow catalyst to be used *during* observe call? Yes, that's more intuitive.
        // Modify observe to take catalysts used: observe(tokenId, catalystsToUse)

        revert ObservationFailed("Observe requires specifying catalyst amount or using useCatalyst separately.");
    }

     /// @dev Observes an NFT, potentially triggering state changes based on randomness, entanglement, and catalysts.
     /// @param tokenId The ID of the token to observe.
     /// @param catalystsToUse The amount of Catalyst tokens to use in this observation.
    function observeWithCatalyst(uint256 tokenId, uint256 catalystsToUse) public nonReentrant whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        if (_isDecayed[tokenId]) revert TokenDecayed(tokenId);

        address owner = ownerOf(tokenId);
        // Allow owner or approved to observe
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert ObservationFailed("Caller not authorized for token");
        }

         // Consume catalysts from caller's balance
        if (_catalystBalances[msg.sender] < catalystsToUse) {
            revert NotEnoughCatalyst(catalystsToUse, _catalystBalances[msg.sender]);
        }
         _catalystBalances[msg.sender] -= catalystsToUse;
         emit CatalystUsed(tokenId, msg.sender, catalystsToUse);

        uint256 randomFactor = _generatePseudoRandomFactor();

        _applyObservationEffect(tokenId, randomFactor, catalystsToUse);

        emit NFTObserved(tokenId, randomFactor, catalystsToUse);
    }


    // --- Decay Functions ---

    /// @dev Manually triggers a decay check for an NFT.
    /// @param tokenId The ID of the token to check for decay.
    function decayState(uint256 tokenId) public nonReentrant whenNotPaused notDecayed(tokenId) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

         // Only allow owner or approved to check for decay
         address owner = ownerOf(tokenId);
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert DecayFailed("Caller not authorized for token");
        }

        uint256 randomFactor = _generatePseudoRandomFactor();
        _decayCheck(tokenId, randomFactor);

         // If it didn't decay, maybe emit an event indicating check occurred?
        // if (!_isDecayed[tokenId]) { /* emit event */ }
    }

     /// @dev Gets the time interval threshold for decay checks.
     /// @return The decay interval in seconds.
     function getDecayInterval() public view returns (uint256) {
        return _decayInterval;
     }


    // --- Catalyst Token Management ---

    /// @dev Mints Catalyst tokens for the caller. Limited by catalystMintAmount.
    function mintCatalyst() public nonReentrant whenNotPaused {
         // Add logic to limit minting rate or total supply if desired
         uint256 amount = _catalystMintAmount; // Amount to mint per call
        _catalystBalances[msg.sender] += amount;
        _totalCatalystSupply += amount;
        emit CatalystMinted(msg.sender, amount, _totalCatalystSupply);
    }

    /// @dev Transfers Catalyst tokens from caller to another address.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    /// @return True if successful.
    function transferCatalyst(address to, uint256 amount) public returns (bool) {
        uint256 senderBalance = _catalystBalances[msg.sender];
        if (senderBalance < amount) {
            revert NotEnoughCatalyst(amount, senderBalance);
        }
        _catalystBalances[msg.sender] -= amount;
        _catalystBalances[to] += amount;
        emit CatalystTransferred(msg.sender, to, amount);
        return true;
    }

    /// @dev Approves a spender to spend a certain amount of Catalyst tokens on caller's behalf.
    /// @param spender The address allowed to spend.
    /// @param amount The maximum amount the spender can spend.
    /// @return True if successful.
    function approveCatalyst(address spender, uint256 amount) public returns (bool) {
        _catalystAllowances[msg.sender][spender] = amount;
        emit CatalystApproved(msg.sender, spender, amount);
        return true;
    }

    /// @dev Returns the amount of Catalyst tokens an owner has allowed a spender to spend.
    /// @param owner The address owning the tokens.
    /// @param spender The address allowed to spend the tokens.
    /// @return The allowance amount.
    function allowanceCatalyst(address owner, address spender) public view returns (uint256) {
        return _catalystAllowances[owner][spender];
    }

     /// @dev Burns a specified amount of Catalyst tokens from the caller's balance.
     /// @param amount The amount of Catalyst tokens to burn.
     function burnCatalyst(uint256 amount) public {
         uint256 senderBalance = _catalystBalances[msg.sender];
         if (senderBalance < amount) {
             revert NotEnoughCatalyst(amount, senderBalance);
         }
         _catalystBalances[msg.sender] -= amount;
         _totalCatalystSupply -= amount;
         emit CatalystBurned(msg.sender, amount, _totalCatalystSupply);
     }


     /// @dev Gets the Catalyst token balance for an address.
     /// @param owner The address to check.
     /// @return The balance.
     function getCatalystBalance(address owner) public view returns (uint256) {
        return _catalystBalances[owner];
     }

     /// @dev Gets the Catalyst allowance for a spender from an owner.
     /// @param owner The owner address.
     /// @param spender The spender address.
     /// @return The allowance.
     function getCatalystAllowance(address owner, address spender) public view returns (uint256) {
        return _catalystAllowances[owner][spender];
     }

     /// @dev Gets the total supply of Catalyst tokens.
     /// @return The total supply.
     function getTotalCatalystSupply() public view returns (uint256) {
        return _totalCatalystSupply;
     }


    // --- Admin Functions (Owner-only) ---

    /// @dev Pauses the contract (owner only).
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Unpauses the contract (owner only).
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @dev Withdraws any ETH accidentally sent to the contract (owner only).
    function withdrawEth() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    /// @dev Sets the maximum number of NFTs that can be minted (owner only).
    /// @param supply The new maximum supply. Set to 0 for no limit.
    function setMaxSupply(uint256 supply) public onlyOwner {
        _maxSupply = supply;
    }

    /// @dev Sets the amount of Catalyst tokens minted per call to mintCatalyst (owner only).
    /// @param amount The new amount.
    function setCatalystMintAmount(uint256 amount) public onlyOwner {
        _catalystMintAmount = amount;
    }

    /// @dev Sets the time interval after which decay is checked (owner only).
    /// @param interval The new interval in seconds.
    function setDecayInterval(uint256 interval) public onlyOwner {
        _decayInterval = interval;
    }

     /// @dev Sets the probability of entanglement breaking during observation (owner only).
     /// @param probBasisPoints The probability in basis points (0-10000).
     function setEntanglementDecayProbability(uint256 probBasisPoints) public onlyOwner {
         if (probBasisPoints > 10000) revert ProbabilityOutOfRange();
        _entanglementDecayProbabilityBasisPoints = probBasisPoints;
     }

     /// @dev Sets the probability of state change during observation (owner only).
     /// @param probBasisPoints The probability in basis points (0-10000).
     function setObservationProbabilities(uint256 probBasisPoints) public onlyOwner {
         if (probBasisPoints > 10000) revert ProbabilityOutOfRange();
         _observationProbabilityBasisPoints = probBasisPoints;
     }

     /// @dev Sets the probability of decay when interval passed (owner only).
      /// @param probBasisPoints The probability in basis points (0-10000).
     function setDecayProbability(uint256 probBasisPoints) public onlyOwner {
         if (probBasisPoints > 10000) revert ProbabilityOutOfRange();
         _decayProbabilityBasisPoints = probBasisPoints;
     }

     /// @dev Sets the multiplier for catalyst effect on probabilities (owner only).
      /// @param multiplier The multiplier in basis points (e.g., 100 for 1x, 200 for 2x).
     function setCatalystEffectMultiplier(uint256 multiplier) public onlyOwner {
        _catalystEffectMultiplier = multiplier;
     }


    // --- Getters (General) ---

     /// @dev Gets the maximum token supply limit.
     /// @return The maximum supply, 0 if no limit.
     function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
     }

     /// @dev Gets the current total number of minted tokens.
     /// @return The current supply.
     function getCurrentSupply() public view returns (uint256) {
         return _tokenIdCounter.current();
     }

      /// @dev Gets the probability of state change during observation (in basis points).
      function getObservationProbability() public view returns (uint256) {
          return _observationProbabilityBasisPoints;
      }

       /// @dev Gets the probability of entanglement breaking during observation (in basis points).
      function getEntanglementDecayProbability() public view returns (uint256) {
           return _entanglementDecayProbabilityBasisPoints;
      }

       /// @dev Gets the probability of decay when interval passed (in basis points).
       function getDecayProbability() public view returns (uint256) {
           return _decayProbabilityBasisPoints;
       }

        /// @dev Gets the multiplier for catalyst effect on probabilities (in basis points).
       function getCatalystEffectMultiplier() public view returns (uint256) {
           return _catalystEffectMultiplier;
       }

      // This would be complex if states had specific transition probabilities.
      // Keeping it simple for now with generic observation and decay probs.
      // function getStateTransitionProbability(NFTState fromState, NFTState toState) public view returns (uint256) { ... }

}

// Minimal Math library dependency to avoid adding OpenZeppelin Math
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
```