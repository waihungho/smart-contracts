Okay, here is a Solidity smart contract implementing a "Quantum Entangled ERC721" with a unique set of features. It focuses on dynamic token state, interaction between tokens, and simulates a simplified "quantum" effect.

This contract is for educational and conceptual purposes. Complex on-chain calculations (like precise continuous energy decay) are approximated or simplified due to gas costs and block time dynamics.

---

**Outline and Function Summary:**

This contract defines an ERC721 non-fungible token with dynamic properties based on a "Quantum Entanglement" theme. Tokens have `energy`, a `decayRate`, can be `entangled` with another token, and can be `observed`, which impacts their state and potentially the state of their entangled partner.

**Core Concepts:**

1.  **Dynamic Energy:** Each token has energy that decays over time based on its `decayRate`. Energy is calculated on demand.
2.  **Entanglement:** Two tokens can be linked. Actions on one might affect the other.
3.  **Observation:** A token can be "observed", collapsing its state (`isObserved = true`). If entangled, the partner token is also observed. Observation might prevent further entanglement or energy manipulation.
4.  **State-Dependent Metadata:** The `tokenURI` should ideally reflect the dynamic state (energy level, observed status, entanglement).

**Key Function Categories:**

1.  **ERC721 Standard Functions:** Basic NFT operations (balance, owner, transfer, approval, tokenURI). Overridden where necessary to integrate dynamic state.
2.  **Token State Management:** Functions to query and update the dynamic state (`energy`, `decayRate`, `observed status`).
3.  **Entanglement Management:** Functions to propose, accept, break, and query entanglement between tokens.
4.  **Observation Mechanics:** Function to 'observe' a token, triggering state collapse and entangled effects.
5.  **Administrative Functions:** Owner-only functions for setup or emergency overrides.
6.  **Helper/Internal Functions:** Logic encapsulation.

**Function Summary (20+ Functions):**

*   `constructor(string memory name_, string memory symbol_)`: Initializes the contract.
*   `name()`: Returns token name.
*   `symbol()`: Returns token symbol.
*   `totalSupply()`: Returns total minted tokens.
*   `balanceOf(address owner)`: Returns number of tokens owned by an address.
*   `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
*   `tokenURI(uint256 tokenId)`: Returns the URI for token metadata (designed to be dynamic).
*   `approve(address to, uint256 tokenId)`: Approves an address to transfer a token.
*   `getApproved(uint256 tokenId)`: Gets the approved address for a token.
*   `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all tokens.
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved.
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (standard).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers token safely (standard).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Transfers token safely with data (standard).
*   `supportsInterface(bytes4 interfaceId)`: ERC165 interface support check.
*   `mintInitialToken(address to, uint256 initialEnergy, uint256 decayRate)`: Mints a new token with initial dynamic state.
*   `getCurrentEnergy(uint256 tokenId)`: Calculates and returns the current energy of a token based on decay.
*   `rechargeEnergy(uint256 tokenId, uint256 amount)`: Adds energy to a token (requires ownership/approval).
*   `getDecayRate(uint256 tokenId)`: Returns the decay rate of a token.
*   `setDecayRate(uint256 tokenId, uint256 newRate)`: Sets the decay rate (owner/approved only, or potentially admin - making it owner/approved).
*   `proposeEntanglement(uint256 tokenId1, uint256 tokenId2)`: Owner of tokenId1 proposes entanglement with tokenId2.
*   `cancelEntanglementProposal(uint256 tokenId1, uint256 tokenId2)`: Owner of tokenId1 cancels a proposal.
*   `acceptEntanglement(uint256 tokenId1, uint256 tokenId2)`: Owner of tokenId2 accepts a proposal from tokenId1.
*   `breakEntanglement(uint256 tokenId)`: Breaks the entanglement link for a token and its partner.
*   `getEntangledPair(uint256 tokenId)`: Returns the token ID entangled with this one, or 0 if not entangled.
*   `isEntangled(uint256 tokenId)`: Checks if a token is entangled.
*   `observeToken(uint256 tokenId)`: Sets the token to observed status and triggers entangled effect.
*   `isObserved(uint256 tokenId)`: Checks if a token is observed.
*   `getMetadataState(uint256 tokenId)`: Helper to get relevant state for dynamic metadata generation off-chain.
*   `setBaseURI(string memory newBaseURI)`: Admin function to update base URI.
*   `adminOverrideObserve(uint256 tokenId, bool status)`: Admin can force observed status.
*   `adminOverrideEntanglement(uint256 tokenId1, uint256 tokenId2)`: Admin can force entanglement.
*   `adminOverrideBreakEntanglement(uint256 tokenId)`: Admin can force break entanglement.
*   `adminSetEnergy(uint256 tokenId, uint256 newEnergy)`: Admin can set energy.
*   `adminSetDecayRate(uint256 tokenId, uint256 newRate)`: Admin can set decay rate.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath adds clarity for intent

/// @title QuantumEntangledERC721
/// @dev An advanced ERC721 contract simulating dynamic state, entanglement, and observation effects.
/// Tokens have energy that decays, can be entangled with another token, and can be observed.
/// Observation of one token can cause its entangled partner to also become observed.
/// This contract is a conceptual exploration of complex on-chain state management and token interaction.
contract QuantumEntangledERC721 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicit use for clarity in calculations

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Token dynamic state
    struct QuantumState {
        uint256 energy;          // Current energy level (can decay)
        uint256 decayRate;       // Energy lost per second
        uint256 lastStateChange; // Timestamp of the last interaction/state update
        bool isObserved;         // If the token's state has been "collapsed"
    }
    mapping(uint256 => QuantumState) private _tokenStates;

    // Entanglement tracking
    mapping(uint256 => uint256) private _entangledWith; // tokenId => entangled tokenId (0 if not entangled)

    // Entanglement proposals (tokenId1 => tokenId2 => proposed)
    mapping(uint256 => mapping(uint256 => bool)) private _entanglementProposals;

    // Base URI for metadata (can be pointed to a dynamic metadata service)
    string private _baseTokenURI;

    // --- Events ---

    event TokenStateUpdated(uint256 indexed tokenId, uint256 energy, uint256 decayRate, bool isObserved);
    event EnergyRecharged(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event DecayRateChanged(uint256 indexed tokenId, uint256 oldRate, uint256 newRate);
    event EntanglementProposed(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed proposer);
    event EntanglementAccepted(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokenObserved(uint256 indexed tokenId);
    event AdminOverride(uint256 indexed tokenId, string action);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {
        // Initial contract owner set by Ownable
    }

    // --- ERC721 Standard Overrides ---

    /// @dev See {IERC721Metadata-tokenURI}.
    /// This implementation prepends a base URI and appends the token ID.
    /// A dynamic metadata service would need to interpret this URI, query the contract's state,
    /// and serve appropriate metadata (e.g., an image reflecting energy level or observed status).
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // Appending token ID allows a metadata service to fetch state via on-chain calls
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    /// @dev Internal function to update token state just before a transfer happens.
    /// This is a good hook to calculate and finalize energy before ownership changes,
    /// although energy is primarily calculated on read (`getCurrentEnergy`).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Only update state if the token is actually being transferred (not mint or burn to zero)
        if (from != address(0) && to != address(0)) {
             // When transferred, update its last interaction time.
             // Energy decay is calculated on read, but this anchors the time.
            _tokenStates[tokenId].lastStateChange = block.timestamp;
            emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, _tokenStates[tokenId].decayRate, _tokenStates[tokenId].isObserved);
        } else if (from == address(0)) {
             // New token minted - initial state set by mint function
        } else if (to == address(0)) {
            // Token burned - clean up entanglement if exists
            if (_isEntangled(tokenId)) {
                 _breakEntanglement(tokenId);
            }
            // State cleanup (mappings don't need explicit deletion in Solidity >= 0.5)
        }
    }


    /// @dev Returns the total number of tokens in existence.
    function totalSupply() public view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @dev See {ERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Include ERC721, ERC721Enumerable, and ERC165 interfaces
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               super.supportsInterface(interfaceId); // Covers ERC165 standard interface
    }

    // --- Custom Token State Management Functions ---

    /// @dev Mints a new Quantum Entangled Token.
    /// Sets initial energy and decay rate.
    /// @param to The recipient address.
    /// @param initialEnergy Initial energy level for the token.
    /// @param decayRate Energy decay per second.
    function mintInitialToken(address to, uint256 initialEnergy, uint256 decayRate) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId); // Use safeMint for ERC721 safety

        _tokenStates[newTokenId] = QuantumState({
            energy: initialEnergy,
            decayRate: decayRate,
            lastStateChange: block.timestamp,
            isObserved: false // Start unobserved
        });

        emit TokenStateUpdated(newTokenId, initialEnergy, decayRate, false);
        return newTokenId;
    }

    /// @dev Calculates and returns the current energy level of a token, considering decay.
    /// Energy calculation is done on read.
    /// @param tokenId The ID of the token.
    /// @return The current energy level.
    function getCurrentEnergy(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId); // Ensure token exists

        QuantumState storage state = _tokenStates[tokenId];
        if (state.isObserved) {
            // Observed tokens might have fixed energy or a different decay model
            // For this version, observed state freezes or sets energy (example: 0)
            // Let's say observation sets energy to 0 for simplicity in this example
            return 0;
        }

        uint256 timeElapsed = block.timestamp - state.lastStateChange;
        uint256 decayedEnergy = timeElapsed.mul(state.decayRate);

        // Ensure energy does not underflow below 0
        if (decayedEnergy >= state.energy) {
            return 0;
        } else {
            return state.energy.sub(decayedEnergy);
        }
    }

    /// @dev Recharges energy for a token. Requires owner or approved address.
    /// Updates the energy state and last state change time.
    /// @param tokenId The ID of the token.
    /// @param amount The amount of energy to add.
    function rechargeEnergy(uint256 tokenId, uint256 amount) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QET: Not owner or approved");
        _requireOwned(tokenId); // Ensure token exists

        QuantumState storage state = _tokenStates[tokenId];
        require(!state.isObserved, "QET: Cannot recharge observed token");

        // First, calculate current energy *before* recharging
        uint256 currentEnergyBeforeRecharge = getCurrentEnergy(tokenId);

        // Update the stored energy level based on current decay + recharge
        state.energy = currentEnergyBeforeRecharge.add(amount); // Add amount to the energy *after* decay calculation
        state.lastStateChange = block.timestamp; // Reset decay timer

        emit EnergyRecharged(tokenId, amount, state.energy);
        emit TokenStateUpdated(tokenId, state.energy, state.decayRate, state.isObserved);
    }

     /// @dev Returns the decay rate of a token.
    /// @param tokenId The ID of the token.
    /// @return The decay rate per second.
    function getDecayRate(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId); // Ensure token exists
        return _tokenStates[tokenId].decayRate;
    }

    /// @dev Sets the decay rate for a token. Requires owner or approved address.
    /// @param tokenId The ID of the token.
    /// @param newRate The new decay rate per second.
    function setDecayRate(uint256 tokenId, uint256 newRate) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QET: Not owner or approved");
        _requireOwned(tokenId); // Ensure token exists
        require(!_tokenStates[tokenId].isObserved, "QET: Cannot change decay rate of observed token");

        uint256 oldRate = _tokenStates[tokenId].decayRate;
        _tokenStates[tokenId].decayRate = newRate;

        emit DecayRateChanged(tokenId, oldRate, newRate);
        emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, newRate, _tokenStates[tokenId].isObserved);
    }


    // --- Entanglement Management Functions ---

    /// @dev Proposes entanglement between two tokens. Owner of tokenId1 calls this.
    /// Requires both tokens to exist, not be the same, not already entangled, and not observed.
    /// @param tokenId1 The token proposing entanglement.
    /// @param tokenId2 The token to propose entanglement with.
    function proposeEntanglement(uint256 tokenId1, uint256 tokenId2) public {
        require(_isApprovedOrOwner(msg.sender, tokenId1), "QET: Not owner or approved of tokenId1");
        _requireOwned(tokenId2); // Ensure tokenId2 exists
        require(tokenId1 != tokenId2, "QET: Cannot entangle token with itself");
        require(!_isEntangled(tokenId1), "QET: Token1 already entangled");
        require(!_isEntangled(tokenId2), "QET: Token2 already entangled");
        require(!_tokenStates[tokenId1].isObserved, "QET: Token1 is observed");
        require(!_tokenStates[tokenId2].isObserved, "QET: Token2 is observed");

        _entanglementProposals[tokenId1][tokenId2] = true;
        emit EntanglementProposed(tokenId1, tokenId2, msg.sender);
    }

     /// @dev Cancels an outstanding entanglement proposal. Owner of tokenId1 calls this.
    /// @param tokenId1 The token that made the proposal.
    /// @param tokenId2 The token the proposal was made to.
    function cancelEntanglementProposal(uint256 tokenId1, uint256 tokenId2) public {
         require(_isApprovedOrOwner(msg.sender, tokenId1), "QET: Not owner or approved of tokenId1");
         require(_entanglementProposals[tokenId1][tokenId2], "QET: Proposal does not exist");

         delete _entanglementProposals[tokenId1][tokenId2];
         // No specific event for cancel, can use log if needed
    }

    /// @dev Accepts an entanglement proposal. Owner of tokenId2 calls this.
    /// Requires a proposal to exist and both tokens to meet entanglement criteria.
    /// @param tokenId1 The token that made the proposal.
    /// @param tokenId2 The token accepting the proposal.
    function acceptEntanglement(uint256 tokenId1, uint256 tokenId2) public {
        require(_isApprovedOrOwner(msg.sender, tokenId2), "QET: Not owner or approved of tokenId2");
        require(_entanglementProposals[tokenId1][tokenId2], "QET: No entanglement proposal exists");
        _requireOwned(tokenId1); // Ensure tokenId1 still exists

        // Double-check entanglement criteria just before accepting
        require(tokenId1 != tokenId2, "QET: Cannot entangle token with itself");
        require(!_isEntangled(tokenId1), "QET: Token1 already entangled"); // Check if status changed since proposal
        require(!_isEntangled(tokenId2), "QET: Token2 already entangled"); // Check if status changed since proposal
        require(!_tokenStates[tokenId1].isObserved, "QET: Token1 is observed");
        require(!_tokenStates[tokenId2].isObserved, "QET: Token2 is observed");


        // Establish entanglement link in both directions
        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1;

        // Clear the proposal
        delete _entanglementProposals[tokenId1][tokenId2];
        // Also clear reverse proposal if it existed (unlikely but safe)
        delete _entanglementProposals[tokenId2][tokenId1];


        emit EntanglementAccepted(tokenId1, tokenId2);
        // Consider emitting TokenStateUpdated for both if entanglement subtly changes state?
        // For this example, let's just emit the acceptance event.
    }

    /// @dev Breaks the entanglement link for a token and its partner.
    /// Can be called by the owner/approved of either entangled token.
    /// @param tokenId The ID of one of the entangled tokens.
    function breakEntanglement(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QET: Not owner or approved of the token");
        _requireOwned(tokenId); // Ensure token exists

        uint256 partnerTokenId = _entangledWith[tokenId];
        require(partnerTokenId != 0, "QET: Token is not entangled");

        _breakEntanglement(tokenId); // Use internal helper
    }

    /// @dev Internal helper to break entanglement for a token.
    /// Clears the entanglement link for both tokens and emits event.
    function _breakEntanglement(uint256 tokenId) internal {
        uint256 partnerTokenId = _entangledWith[tokenId];
        require(partnerTokenId != 0, "QET: Token is not entangled (internal error)");

        // Clear links
        delete _entangledWith[tokenId];
        delete _entangledWith[partnerTokenId];

        emit EntanglementBroken(tokenId, partnerTokenId);
        // Consider emitting TokenStateUpdated for both
    }

    /// @dev Gets the token ID entangled with the given token.
    /// @param tokenId The ID of the token.
    /// @return The ID of the entangled partner, or 0 if not entangled.
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
         _requireOwned(tokenId); // Ensure token exists
         return _entangledWith[tokenId];
    }

    /// @dev Checks if a token is entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view returns (bool) {
        // No _requireOwned here, allows checking if a token *could* be entangled
        return _isEntangled(tokenId);
    }

    /// @dev Internal helper to check if a token is entangled.
     function _isEntangled(uint256 tokenId) internal view returns (bool) {
        return _entangledWith[tokenId] != 0;
    }

    /// @dev Checks if there is an entanglement proposal between two tokens.
    /// @param tokenId1 The proposer token.
    /// @param tokenId2 The proposed token.
    /// @return True if a proposal exists from tokenId1 to tokenId2.
    function getEntanglementProposal(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
        // No _requireOwned here, allows checking proposals regardless of ownership status
        return _entanglementProposals[tokenId1][tokenId2];
    }


    // --- Observation Mechanics ---

    /// @dev "Observes" a token, collapsing its state and potentially its entangled partner's state.
    /// Requires owner or approved address.
    /// @param tokenId The ID of the token to observe.
    function observeToken(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "QET: Not owner or approved");
        _requireOwned(tokenId); // Ensure token exists
        require(!_tokenStates[tokenId].isObserved, "QET: Token is already observed");

        // Perform the observation
        _tokenStates[tokenId].isObserved = true;
        _tokenStates[tokenId].lastStateChange = block.timestamp; // Mark the time of observation
        // For simplicity, observation in this example also sets energy to 0
        // A more complex model might capture energy *at* observation
        _tokenStates[tokenId].energy = 0;


        emit TokenObserved(tokenId);
        emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, _tokenStates[tokenId].decayRate, _tokenStates[tokenId].isObserved);

        // Quantum Entanglement Effect: If entangled, observe the partner too
        uint256 partnerTokenId = _entangledWith[tokenId];
        if (partnerTokenId != 0) {
             // Check partner exists and isn't already observed to avoid re-triggering
            if (_exists(partnerTokenId) && !_tokenStates[partnerTokenId].isObserved) {
                 _handleEntanglementObservation(partnerTokenId);
            }
        }
    }

    /// @dev Internal helper to handle the entangled observation effect.
    /// Sets the partner token to observed status.
    /// @param tokenId The ID of the token being observed due to entanglement.
    function _handleEntanglementObservation(uint256 tokenId) internal {
        // Set the entangled partner to observed state
        _tokenStates[tokenId].isObserved = true;
        _tokenStates[tokenId].lastStateChange = block.timestamp; // Mark time of secondary observation
        // For simplicity, entangled observation also sets energy to 0
        _tokenStates[tokenId].energy = 0;

        emit TokenObserved(tokenId); // Emit event for the partner token
         emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, _tokenStates[tokenId].decayRate, _tokenStates[tokenId].isObserved);

        // Note: This could potentially chain if partner was also entangled with a third, etc.,
        // but our entanglement is pairwise (_entangledWith maps to a single partner),
        // so the effect stops after one step.
    }


    /// @dev Checks if a token has been observed.
    /// @param tokenId The ID of the token.
    /// @return True if the token is observed, false otherwise.
    function isObserved(uint256 tokenId) public view returns (bool) {
        _requireOwned(tokenId); // Ensure token exists
        return _tokenStates[tokenId].isObserved;
    }

    // --- Dynamic Metadata Helper ---

    /// @dev Provides the key dynamic state variables for a token.
    /// Intended to be called by an off-chain metadata service to generate `tokenURI` content dynamically.
    /// @param tokenId The ID of the token.
    /// @return energy The current energy level.
    /// @return decayRate The decay rate.
    /// @return isObserved The observed status.
    /// @return entangledPartnerId The ID of the entangled partner (0 if none).
    function getMetadataState(uint256 tokenId) public view returns (uint256 energy, uint256 decayRate, bool isObserved, uint256 entangledPartnerId) {
        _requireOwned(tokenId); // Ensure token exists
        QuantumState storage state = _tokenStates[tokenId];

        return (
            getCurrentEnergy(tokenId), // Calculate energy at this moment
            state.decayRate,
            state.isObserved,
            _entangledWith[tokenId]
        );
    }


    // --- Administrative Functions (Owner-only) ---

    /// @dev Admin function to set the base URI for metadata.
    /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

     /// @dev Admin function to force observed status on a token.
    /// Bypasses regular observe logic (e.g., approval, entanglement effect).
    /// Use with caution.
    /// @param tokenId The ID of the token.
    /// @param status The desired observed status.
    function adminOverrideObserve(uint256 tokenId, bool status) public onlyOwner {
        _requireOwned(tokenId); // Ensure token exists
        _tokenStates[tokenId].isObserved = status;
        _tokenStates[tokenId].lastStateChange = block.timestamp; // Update time

        // If setting to observed, and it's entangled, force partner observed too
        if (status && _isEntangled(tokenId)) {
             uint256 partnerId = _entangledWith[tokenId];
             if (_exists(partnerId)) { // Ensure partner still exists
                  _tokenStates[partnerId].isObserved = true;
                  _tokenStates[partnerId].lastStateChange = block.timestamp;
                  // Could emit AdminOverride for partner too
             }
        }

        emit AdminOverride(tokenId, "ObservedStatusSet");
        emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, _tokenStates[tokenId].decayRate, _tokenStates[tokenId].isObserved);
    }

    /// @dev Admin function to force entanglement between two tokens.
    /// Bypasses proposal/acceptance and checks like observed status. Use with caution.
    /// @param tokenId1 The first token.
    /// @param tokenId2 The second token.
    function adminOverrideEntanglement(uint256 tokenId1, uint256 tokenId2) public onlyOwner {
        _requireOwned(tokenId1);
        _requireOwned(tokenId2);
        require(tokenId1 != tokenId2, "QET: Cannot entangle token with itself");

        // Break existing entanglement for both, if any
        if (_isEntangled(tokenId1)) _breakEntanglement(tokenId1);
        if (_isEntangled(tokenId2)) _breakEntanglement(tokenId2);

        // Clear any outstanding proposals involving these two
        delete _entanglementProposals[tokenId1][tokenId2];
        delete _entanglementProposals[tokenId2][tokenId1];

        // Force entanglement link
        _entangledWith[tokenId1] = tokenId2;
        _entangledWith[tokenId2] = tokenId1;

        emit AdminOverride(tokenId1, "EntanglementSet");
        emit AdminOverride(tokenId2, "EntanglementSet");
        emit EntanglementAccepted(tokenId1, tokenId2); // Use this event to signal link creation
    }

     /// @dev Admin function to force break entanglement for a token.
    /// Bypasses regular break logic (e.g., approval). Use with caution.
    /// @param tokenId The ID of the token.
    function adminOverrideBreakEntanglement(uint256 tokenId) public onlyOwner {
        _requireOwned(tokenId);
        if (_isEntangled(tokenId)) {
             emit AdminOverride(tokenId, "BreakEntanglementForced");
            _breakEntanglement(tokenId); // Use internal helper
        } else {
             // Already not entangled, no action needed
        }
    }


     /// @dev Admin function to set energy level directly. Bypasses recharge logic.
    /// Use with caution.
    /// @param tokenId The ID of the token.
    /// @param newEnergy The new energy level.
    function adminSetEnergy(uint256 tokenId, uint256 newEnergy) public onlyOwner {
        _requireOwned(tokenId);
        _tokenStates[tokenId].energy = newEnergy;
        _tokenStates[tokenId].lastStateChange = block.timestamp; // Anchor decay calculation from now

        emit AdminOverride(tokenId, "EnergySet");
        emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, _tokenStates[tokenId].decayRate, _tokenStates[tokenId].isObserved);
    }

    /// @dev Admin function to set decay rate directly. Bypasses regular logic.
    /// Use with caution.
    /// @param tokenId The ID of the token.
    /// @param newRate The new decay rate.
    function adminSetDecayRate(uint256 tokenId, uint256 newRate) public onlyOwner {
        _requireOwned(tokenId);
        _tokenStates[tokenId].decayRate = newRate;

        emit AdminOverride(tokenId, "DecayRateSet");
        emit TokenStateUpdated(tokenId, _tokenStates[tokenId].energy, _tokenStates[tokenId].decayRate, _tokenStates[tokenId].isObserved);
    }

    // --- Internal Helpers ---

    /// @dev Ensures a token exists. Reverts otherwise.
    function _requireOwned(uint256 tokenId) internal view {
         require(_exists(tokenId), "QET: ERC721 query for nonexistent token");
    }

    /// @dev Converts a uint256 to a string (utility function).
    /// Borrowed from OpenZeppelin Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
```