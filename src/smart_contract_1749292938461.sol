Okay, let's create a smart contract based on the concept of "Quantum Essences" – unique digital entities with dynamic, probabilistic, and interdependent states, inspired by quantum mechanics principles like observation affecting state, entanglement, decay, and combination. This is distinct from typical ERC721s by having complex, mutable state influenced by interactions and time, and distinct from standard DeFi/DAO by focusing on the intrinsic properties and interactions of the tokens themselves.

We'll create a contract called `QuantumForge` that mints, manages, and allows interaction with these `QuantumEssences`.

---

**QuantumForge Smart Contract**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary interfaces/libraries (minimal ERC721).
2.  **Error Definitions:** Custom errors for clarity.
3.  **Events:** Announce key actions and state changes.
4.  **Enums:** Define possible states for a Quantum Essence.
5.  **Structs:** Define the structure of a `QuantumEssence`.
6.  **State Variables:** Store contract data (owner, token counter, essence data mapping, owner mappings for ERC721, Flux balances).
7.  **Modifiers:** Restrict function access (`onlyOwner`, `onlyEssenceOwner`, `onlyApprovedOrOwner`).
8.  **ERC721 Implementation (Minimal):** Basic functions for token ownership and transfer.
9.  **Internal Helper Functions:** Logic for token existence, ownership checks, transfers, state propagation.
10. **Quantum Essence Core Lifecycle:** Functions for forging, burning, basic interactions.
11. **Dynamic State & Interaction Functions:** Functions for observing, injecting energy, stabilizing, entangling, disentangling.
12. **Complex Interaction Functions:** Combining and splitting essences.
13. **Time-Based/External Trigger Functions:** Decay and evolution.
14. **Resource Management:** Flux claiming and balance.
15. **View Functions:** Get data about essences and the contract state.
16. **Admin Functions:** Owner-only controls.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `forgeEssence(uint256 initialEnergy, uint256 initialCoherence)`: Creates a new Quantum Essence, requires Flux payment.
3.  `burnEssence(uint256 tokenId)`: Allows an owner to destroy their essence.
4.  `injectEnergy(uint256 tokenId, uint256 amount)`: Adds energy to an essence, costs Flux, affects state/entropy.
5.  `observeEssence(uint256 tokenId)`: Reads an essence's state, potentially causing probabilistic state changes based on coherence/entropy. Triggers decay check.
6.  `stabilizeEssence(uint256 tokenId, uint256 fluxAmount)`: Uses Flux to reduce an essence's entropy and increase coherence.
7.  `entangleEssences(uint256 tokenId1, uint256 tokenId2)`: Links two essences, making their states potentially interdependent. Requires energy from both.
8.  `disentangleEssence(uint256 tokenId)`: Breaks entanglement for a single essence (affecting its links and linked partners). Costs energy.
9.  `combineEssences(uint256 tokenId1, uint256 tokenId2)`: Merges two essences into one, burning the second and adding/averaging properties to the first, increasing entropy.
10. `splitEssence(uint256 tokenId)`: Splits one essence into two, burning the original and creating two new ones with diluted properties and increased entropy.
11. `decayEssences(uint256[] calldata tokenIds)`: Publicly callable function to trigger decay logic for specific essences that are past their observation threshold. May reduce stats or burn the essence if decay is severe. Rewards caller.
12. `evolveEssence(uint256 tokenId)`: Allows an essence meeting specific criteria (age, state, stats) to evolve to a new generation, resetting entropy and boosting potential. Costs Flux and energy.
13. `claimFlux()`: Allows users to claim a small amount of Flux based on time elapsed since last claim.
14. `getEssenceState(uint256 tokenId)`: View function: Returns the current state of an essence.
15. `getEssenceProperties(uint256 tokenId)`: View function: Returns detailed properties of an essence.
16. `getLinkedEssences(uint256 tokenId)`: View function: Returns the IDs of essences entangled with the given one.
17. `getTotalEssences()`: View function: Returns the total number of essences minted.
18. `getFluxBalance(address account)`: View function: Returns the Flux balance of an account.
19. `getEssencesByOwner(address owner)`: View function: Returns a list of token IDs owned by an address (potentially gas-intensive for many tokens).
20. `adminSetFluxClaimRate(uint256 ratePerSecond)`: Owner-only: Sets the rate at which Flux can be claimed.
21. `adminSetDecayParameters(uint256 observationThreshold, uint256 energyDecayRate, uint256 coherenceDecayRate)`: Owner-only: Sets parameters for the decay process.
22. `adminSetForgeCost(uint256 cost)`: Owner-only: Sets the Flux cost for forging.
23. `adminRescueFunds(address tokenAddress, uint256 amount)`: Owner-only: Recovers mistakenly sent ERC20 tokens (excluding this contract's 'Flux' balance which is internal).
24. `balanceOf(address owner)`: ERC721 standard: Returns the number of tokens owned by an address.
25. `ownerOf(uint256 tokenId)`: ERC721 standard: Returns the owner of a token.
26. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers a token.
27. `approve(address to, uint256 tokenId)`: ERC721 standard: Approves an address to transfer a token.
28. `getApproved(uint256 tokenId)`: ERC721 standard: Returns the approved address for a token.
29. `setApprovalForAll(address operator, bool approved)`: ERC721 standard: Sets approval for an operator for all tokens.
30. `isApprovedForAll(address owner, address operator)`: ERC721 standard: Checks if an operator is approved for all tokens.

*(Note: We already exceeded 20 functions significantly, including standard ERC721. The complex interactions (observe, entangle, combine, split, decay, evolve) are the core advanced/creative aspects.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal ERC721 implementation for ownership tracking
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address approved);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Helper interface for ERC165 (standard interface detection)
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Helper interface for receiving ERC721 tokens
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract QuantumForge is IERC721, IERC165 {

    // --- Errors ---
    error NotOwner();
    error NotEssenceOwner();
    error NotApprovedOrOwner();
    error EssenceDoesNotExist();
    error NotEnoughFlux();
    error InsufficientEnergy();
    error AlreadyEntangled();
    error NotEntangled();
    error CannotCombineSelf();
    error CannotSplitEntangled();
    error EvolutionConditionsNotMet();
    error CannotClaimFluxYet();
    error InvalidAmount();


    // --- Events ---
    event EssenceForged(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint256 initialCoherence);
    event EssenceBurned(uint256 indexed tokenId, address indexed owner);
    event EnergyInjected(uint256 indexed tokenId, uint256 amount, uint256 newEnergy);
    event StateChanged(uint256 indexed tokenId, EssenceState oldState, EssenceState newState);
    event EssenceStabilized(uint256 indexed tokenId, uint256 fluxUsed, uint256 newCoherence, uint256 newEntropy);
    event EssencesEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EssenceDisentangled(uint256 indexed tokenId, uint256 indexed partnerTokenId);
    event EssencesCombined(uint256 indexed primaryTokenId, uint256 indexed consumedTokenId, uint256 newEnergy, uint256 newCoherence, uint256 newEntropy);
    event EssenceSplit(uint256 indexed originalTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2);
    event EssenceDecayed(uint256 indexed tokenId, uint256 energyLost, uint256 coherenceLost, uint256 newEntropy);
    event EssenceEvolved(uint256 indexed tokenId, uint256 newGeneration);
    event FluxClaimed(address indexed account, uint256 amount);
    event FluxPaid(address indexed account, uint256 amount);


    // --- Enums ---
    enum EssenceState {
        Stable,      // Relatively predictable state
        Volatile,    // Prone to change, especially upon observation
        Entangled,   // Linked to another essence
        Decaying,    // Losing properties over time/lack of observation
        Evolved      // Has undergone transformation
        // More states could be added: e.g., QuantumLocked, Harmonized, etc.
    }


    // --- Structs ---
    struct QuantumEssence {
        uint256 tokenId;
        EssenceState state;
        uint256 energy;       // Resource/potential within the essence
        uint256 coherence;    // Predictability, resistance to state change
        uint256 entropy;      // Disorder, increases state volatility and decay rate
        uint256 genesisTime;  // Timestamp of creation
        uint256 lastObservedTime; // Timestamp of last observation or significant interaction
        uint256 lastDecayCheckTime; // Timestamp of last decay check
        uint256 generation;   // Evolutionary generation
        uint256[] linkedEssences; // Token IDs of entangled essences
        address owner;        // Stored directly for easier access (redundant with ERC721 mapping, but convenient)
    }


    // --- State Variables ---
    address public owner;
    uint256 private _currentTokenId;

    mapping(uint256 => QuantumEssence) private _essences; // tokenId => essence data
    mapping(address => uint256) private _fluxBalances;   // owner address => Flux balance (internal resource)
    mapping(address => uint256) private _lastFluxClaimTime; // owner address => timestamp of last flux claim

    // ERC721 State
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Admin settable parameters
    uint256 public forgeCost = 100; // Flux cost to forge a new essence
    uint256 public fluxClaimRate = 1; // Flux per second claim rate
    uint256 public observationDecayThreshold = 24 hours; // Time after which decay starts if not observed
    uint256 public energyDecayRate = 1; // Energy lost per decay step per day
    uint256 public coherenceDecayRate = 1; // Coherence lost per decay step per day
    uint256 public entropyDecayFactor = 10; // Entropy influence on decay (higher = faster decay)


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyEssenceOwner(uint256 tokenId) {
        address essenceOwner = ownerOf(tokenId);
        if (essenceOwner != msg.sender) revert NotEssenceOwner();
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        address essenceOwner = ownerOf(tokenId);
        if (essenceOwner != msg.sender && !isApprovedForAll(essenceOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotApprovedOrOwner();
        }
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        _currentTokenId = 0; // Start token IDs from 1 usually, let's use 0 here for simplicity or 1. Let's use 1.
        _currentTokenId = 1;
    }


    // --- ERC721 Implementation (Minimal) ---

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        // ERC721 interface ID: 0x80ac58cd
        // ERC165 interface ID: 0x01ffc9a7
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert InvalidAmount(); // Common practice check
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address tokenOwner = _essences[tokenId].owner; // Use our struct's stored owner
        if (tokenOwner == address(0)) revert EssenceDoesNotExist();
        return tokenOwner;
    }

    function approve(address to, uint256 tokenId) public override {
        address tokenOwner = ownerOf(tokenId); // Check if token exists
        if (tokenOwner != msg.sender && !isApprovedForAll(tokenOwner, msg.sender)) {
            revert NotApprovedOrOwner();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        // Doesn't revert if token doesn't exist, returns address(0)
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check if sender is owner, approved, or operator
        if (ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
             revert NotApprovedOrOwner();
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        _transfer(from, to, tokenId);
        // Check if the recipient is a contract and can receive ERC721 tokens
        require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // --- Internal ERC721 Helpers ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _essences[tokenId].owner != address(0);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert InvalidAmount(); // Should not happen if called correctly but double check
        if (to == address(0)) revert InvalidAmount();

        // Clear approvals for the transferring token
        delete _tokenApprovals[tokenId];

        // Update balances
        _balances[from]--;
        _balances[to]++;

        // Update owner in the struct (also implies existence)
        _essences[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidAmount();
        if (_exists(tokenId)) revert InvalidAmount(); // Should not happen with _currentTokenId logic

        _balances[to]++;
        _essences[tokenId] = QuantumEssence(tokenId, EssenceState.Stable, 0, 0, 0, block.timestamp, block.timestamp, block.timestamp, 1, new uint256[](0), to);

        emit Transfer(address(0), to, tokenId);
    }

     function _burn(uint256 tokenId) internal {
        address tokenOwner = ownerOf(tokenId); // Reverts if token doesn't exist

        // Handle disentanglement for this essence and its partners
        if (_essences[tokenId].state == EssenceState.Entangled) {
             uint256[] memory linked = _essences[tokenId].linkedEssences;
             for (uint256 i = 0; i < linked.length; i++) {
                _removeLink(linked[i], tokenId); // Remove link from partners
                // Optional: Change state of partners if they were only linked to this one
                if (_essences[linked[i]].linkedEssences.length == 0) {
                     _changeState(linked[i], EssenceState.Stable); // Example transition
                }
             }
        }

        // Clear approvals
        delete _tokenApprovals[tokenId];
        delete _operatorApprovals[tokenOwner][address(this)]; // Clear operator approvals granted by contract

        // Update balance
        _balances[tokenOwner]--;

        // Delete the essence data
        delete _essences[tokenId];

        emit EssenceBurned(tokenId, tokenOwner);
        emit Transfer(tokenOwner, address(0), tokenId);
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes calldata data) private returns (bytes4) {
        if (to.code.length == 0) {
            return 0; // Not a contract, no check needed
        }
        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
            return retval;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                /// @solidity exclusive
                revert(string(reason));
            }
        }
    }


    // --- Quantum Essence Core Lifecycle ---

    /// @notice Creates a new Quantum Essence, requiring Flux payment.
    /// @param initialEnergy Initial energy level for the new essence.
    /// @param initialCoherence Initial coherence level for the new essence.
    /// @return The tokenId of the newly forged essence.
    function forgeEssence(uint256 initialEnergy, uint256 initialCoherence) public returns (uint256) {
        if (_fluxBalances[msg.sender] < forgeCost) revert NotEnoughFlux();

        _fluxBalances[msg.sender] -= forgeCost;
        emit FluxPaid(msg.sender, forgeCost);

        uint256 newTokenId = _currentTokenId++;
        // Mint function handles owner assignment and basic struct initialization
        _mint(msg.sender, newTokenId);

        // Set initial dynamic properties
        _essences[newTokenId].energy = initialEnergy;
        _essences[newTokenId].coherence = initialCoherence;
        // Entropy starts low
        _essences[newTokenId].entropy = 1; // Start with minimal entropy

        emit EssenceForged(newTokenId, msg.sender, initialEnergy, initialCoherence);
        return newTokenId;
    }

    /// @notice Allows the owner of an essence to destroy it.
    /// @param tokenId The ID of the essence to burn.
    function burnEssence(uint256 tokenId) public onlyEssenceOwner(tokenId) {
        _burn(tokenId);
    }


    // --- Dynamic State & Interaction Functions ---

    /// @notice Adds energy to a Quantum Essence, costing Flux.
    /// @param tokenId The ID of the essence.
    /// @param amount The amount of energy to inject.
    function injectEnergy(uint256 tokenId, uint256 amount) public onlyApprovedOrOwner(tokenId) {
        if (!_exists(tokenId)) revert EssenceDoesNotExist();
        // Define cost based on amount or other factors
        uint256 cost = amount; // Simple 1:1 cost for now
        if (_fluxBalances[msg.sender] < cost) revert NotEnoughFlux();

        _fluxBalances[msg.sender] -= cost;
        emit FluxPaid(msg.sender, cost);

        QuantumEssence storage essence = _essences[tokenId];
        essence.energy += amount;
        // Injecting energy could increase volatility/entropy
        essence.entropy += amount / 10; // Example effect

        // Check if state changes due to high energy or entropy
        _assessStateChange(tokenId);

        emit EnergyInjected(tokenId, amount, essence.energy);
    }

    /// @notice Reads an essence's state and properties. May trigger a state change based on its coherence/entropy.
    /// @param tokenId The ID of the essence to observe.
    function observeEssence(uint256 tokenId) public {
        if (!_exists(tokenId)) revert EssenceDoesNotExist();

        QuantumEssence storage essence = _essences[tokenId];

        // Decay check based on last observation time
        _applyDecay(tokenId);

        essence.lastObservedTime = block.timestamp; // Update observation time

        // Probabilistic state change upon observation (Heisenberg principle inspiration)
        // Chance of volatility increases with entropy and decreases with coherence.
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, essence.energy, essence.coherence, essence.entropy))) % 1000;
        uint256 volatilityChance = (essence.entropy * 100) / (essence.coherence + 1); // Higher entropy, lower coherence = higher chance

        if (randomFactor < volatilityChance && essence.state != EssenceState.Volatile && essence.state != EssenceState.Entangled) {
            _changeState(tokenId, EssenceState.Volatile);
        } else if (randomFactor > 950 && essence.state == EssenceState.Volatile) {
             // Small chance to become stable if very low entropy/high coherence AND volatile
             if (essence.entropy < 10 && essence.coherence > 50) {
                 _changeState(tokenId, EssenceState.Stable);
             }
        }
         // Observing an entangled essence propagates a weaker observation effect to partners
        if (essence.state == EssenceState.Entangled) {
            _propagateEntanglement(tokenId, 1); // Propagate intensity 1 (can be dynamic)
        }

        // No explicit return, state changes are emitted via events.
        // User can call view functions after to see the results.
    }

    /// @notice Uses Flux to reduce an essence's entropy and potentially increase coherence, making it more stable.
    /// @param tokenId The ID of the essence.
    /// @param fluxAmount The amount of Flux to use.
    function stabilizeEssence(uint256 tokenId, uint256 fluxAmount) public onlyApprovedOrOwner(tokenId) {
        if (!_exists(tokenId)) revert EssenceDoesNotExist();
        if (_fluxBalances[msg.sender] < fluxAmount) revert NotEnoughFlux();
        if (fluxAmount == 0) revert InvalidAmount();

        _fluxBalances[msg.sender] -= fluxAmount;
        emit FluxPaid(msg.sender, fluxAmount);

        QuantumEssence storage essence = _essences[tokenId];

        // Reduce entropy (cannot go below 0)
        essence.entropy = essence.entropy > fluxAmount ? essence.entropy - fluxAmount : 0;

        // Increase coherence based on Flux used and current entropy (more effective at high entropy)
        uint256 coherenceIncrease = (fluxAmount * (essence.entropy + 10)) / 100; // Example formula
        essence.coherence += coherenceIncrease;

        // Check if state changes due to stabilization
        _assessStateChange(tokenId);

        emit EssenceStabilized(tokenId, fluxAmount, essence.coherence, essence.entropy);
    }

    /// @notice Links two essences together, making their states potentially interdependent.
    /// @param tokenId1 The ID of the first essence.
    /// @param tokenId2 The ID of the second essence.
    function entangleEssences(uint256 tokenId1, uint256 tokenId2) public {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert EssenceDoesNotExist();
        // Both must be owned by the caller or approved
        if (ownerOf(tokenId1) != msg.sender && !isApprovedForAll(ownerOf(tokenId1), msg.sender)) revert NotApprovedOrOwner();
        if (ownerOf(tokenId2) != msg.sender && !isApprovedForAll(ownerOf(tokenId2), msg.sender)) revert NotApprovedOrOwner();

        if (tokenId1 == tokenId2) revert InvalidAmount();

        QuantumEssence storage essence1 = _essences[tokenId1];
        QuantumEssence storage essence2 = _essences[tokenId2];

        // Prevent entangling if already entangled with each other or too many links
        if (_isLinked(tokenId1, tokenId2) || essence1.linkedEssences.length >= 5 || essence2.linkedEssences.length >= 5) revert AlreadyEntangled(); // Arbitrary link limit

        // Cost energy from both essences? Or Flux? Let's say a small energy cost from each.
        uint256 entanglementCost = 10;
        if (essence1.energy < entanglementCost || essence2.energy < entanglementCost) revert InsufficientEnergy();

        essence1.energy -= entanglementCost;
        essence2.energy -= entanglementCost;

        // Add links to both
        essence1.linkedEssences.push(tokenId2);
        essence2.linkedEssences.push(tokenId1);

        // Change states to Entangled
        _changeState(tokenId1, EssenceState.Entangled);
        _changeState(tokenId2, EssenceState.Entangled);

        emit EssencesEntangled(tokenId1, tokenId2);
    }

    /// @notice Breaks an entanglement link for a single essence. Affects linked partners.
    /// @param tokenId The ID of the essence to disentangle.
    function disentangleEssence(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
         if (!_exists(tokenId)) revert EssenceDoesNotExist();

         QuantumEssence storage essence = _essences[tokenId];
         if (essence.state != EssenceState.Entangled) revert NotEntangled();

         // Cost energy to break the link
         uint256 disentangleCost = 20;
         if (essence.energy < disentangleCost) revert InsufficientEnergy();
         essence.energy -= disentangleCost;

         uint256[] memory linked = essence.linkedEssences;
         essence.linkedEssences = new uint256[](0); // Clear all links for this essence

         // Remove the link from partner essences
         for (uint256 i = 0; i < linked.length; i++) {
             if (_exists(linked[i])) { // Check if partner still exists
                 _removeLink(linked[i], tokenId);
                  // If the partner is no longer linked to anything, change its state
                 if (_essences[linked[i]].linkedEssences.length == 0) {
                     _changeState(linked[i], EssenceState.Stable); // Example transition
                 }
             }
         }

         // Change this essence's state
         _changeState(tokenId, EssenceState.Stable); // Example transition after disentanglement

         // Emit events for all disentangled partners
         for (uint256 i = 0; i < linked.length; i++) {
             emit EssenceDisentangled(tokenId, linked[i]);
         }
    }

    // --- Complex Interaction Functions ---

    /// @notice Combines two essences into one. The `primaryTokenId` absorbs properties from `consumedTokenId`, which is burned. Increases entropy.
    /// @param primaryTokenId The essence that will remain and absorb properties.
    /// @param consumedTokenId The essence that will be burned.
    function combineEssences(uint256 primaryTokenId, uint256 consumedTokenId) public {
        if (!_exists(primaryTokenId) || !_exists(consumedTokenId)) revert EssenceDoesNotExist();
        if (primaryTokenId == consumedTokenId) revert CannotCombineSelf();

        // Both must be owned by the caller or approved
        if (ownerOf(primaryTokenId) != msg.sender && !isApprovedForAll(ownerOf(primaryTokenId), msg.sender)) revert NotApprovedOrOwner();
        if (ownerOf(consumedTokenId) != msg.sender && !isApprovedForAll(ownerOf(consumedTokenId), msg.sender)) revert NotApprovedOrOwner();

        QuantumEssence storage primary = _essences[primaryTokenId];
        QuantumEssence storage consumed = _essences[consumedTokenId];

        // Prevent combining entangled essences for simplicity, or add logic to handle links
        if (primary.state == EssenceState.Entangled || consumed.state == EssenceState.Entangled) revert AlreadyEntangled(); // Simplify: require disentanglement first

        // Combine properties (example logic)
        primary.energy += consumed.energy / 2; // Add half of consumed's energy
        primary.coherence = (primary.coherence + consumed.coherence) / 2; // Average coherence
        primary.entropy += consumed.entropy + 10; // Sum entropy + base increase

        // Burn the consumed essence
        _burn(consumedTokenId);

        // Assess primary essence state after combination
        _assessStateChange(primaryTokenId);

        emit EssencesCombined(primaryTokenId, consumedTokenId, primary.energy, primary.coherence, primary.entropy);
    }

    /// @notice Splits one essence into two new ones. The original is burned, and two new ones are minted with diluted properties and increased entropy.
    /// @param tokenId The ID of the essence to split.
    /// @return An array containing the token IDs of the two newly created essences.
    function splitEssence(uint256 tokenId) public onlyApprovedOrOwner(tokenId) returns (uint256[] memory) {
        if (!_exists(tokenId)) revert EssenceDoesNotExist();

        QuantumEssence storage original = _essences[tokenId];

        // Prevent splitting entangled essences
        if (original.state == EssenceState.Entangled) revert CannotSplitEntangled();

        // Cost Flux to perform the split
        uint256 splitCost = forgeCost * 2; // Splitting is like forging two, maybe more?
        if (_fluxBalances[msg.sender] < splitCost) revert NotEnoughFlux();
         _fluxBalances[msg.sender] -= splitCost;
        emit FluxPaid(msg.sender, splitCost);


        // Calculate properties for the two new essences (example: half stats, more entropy)
        uint256 newEnergy = original.energy / 2;
        uint256 newCoherence = original.coherence / 2;
        uint256 newEntropy = original.entropy + 20; // Significant entropy increase

        // Burn the original essence *before* minting new ones to avoid ID clashes if using simple counter
        _burn(tokenId); // _burn handles unlinking, etc.

        // Mint two new essences
        uint256 newTokenId1 = _currentTokenId++;
        uint256 newTokenId2 = _currentTokenId++;

        _mint(msg.sender, newTokenId1);
        _mint(msg.sender, newTokenId2);

        // Set properties for the new essences
        _essences[newTokenId1].energy = newEnergy;
        _essences[newTokenId1].coherence = newCoherence;
        _essences[newTokenId1].entropy = newEntropy;
         _essences[newTokenId1].genesisTime = block.timestamp;
        _essences[newTokenId1].lastObservedTime = block.timestamp;
        _essences[newTokenId1].lastDecayCheckTime = block.timestamp;


        _essences[newTokenId2].energy = newEnergy;
        _essences[newTokenId2].coherence = newCoherence;
        _essences[newTokenId2].entropy = newEntropy;
        _essences[newTokenId2].genesisTime = block.timestamp;
        _essences[newTokenId2].lastObservedTime = block.timestamp;
        _essences[newToken2].lastDecayCheckTime = block.timestamp;


        // New essences start in Volatile state due to disruption
        _changeState(newTokenId1, EssenceState.Volatile);
        _changeState(newTokenId2, EssenceState.Volatile);


        emit EssenceSplit(tokenId, newTokenId1, newTokenId2);

        uint256[] memory newTokens = new uint256[](2);
        newTokens[0] = newTokenId1;
        newTokens[1] = newTokenId2;
        return newTokens;
    }


    // --- Time-Based/External Trigger Functions ---

    /// @notice Allows anyone to trigger the decay process for essences that haven't been observed recently.
    /// Incentivizes maintaining the system state.
    /// @param tokenIds An array of essence IDs to check for decay.
    function decayEssences(uint256[] calldata tokenIds) public {
        uint256 callerReward = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (_exists(tokenId)) {
                QuantumEssence storage essence = _essences[tokenId];
                uint256 timeSinceLastObservation = block.timestamp - essence.lastObservedTime;

                // Only apply decay if past the threshold and not already marked as Decaying (or force re-check)
                if (timeSinceLastObservation > observationDecayThreshold || essence.state == EssenceState.Decaying) {
                     _applyDecay(tokenId);
                     callerReward += 1; // Small reward per essence decayed
                }
            }
        }
        if (callerReward > 0) {
             // Reward caller with Flux from a system pool or by minting (need to manage Flux supply)
             // Simple model: Mint Flux to the caller (implies infinite supply)
             _fluxBalances[msg.sender] += callerReward;
             emit FluxClaimed(msg.sender, callerReward);
        }
    }

     /// @dev Internal function to apply decay effects to a single essence.
     /// @param tokenId The ID of the essence to decay.
    function _applyDecay(uint256 tokenId) internal {
        QuantumEssence storage essence = _essences[tokenId];
        uint256 timeSinceLastObservation = block.timestamp - essence.lastObservedTime;
        uint256 timeSinceLastDecayCheck = block.timestamp - essence.lastDecayCheckTime;

        // Only decay if past threshold and time has passed since last check
        if (timeSinceLastObservation <= observationDecayThreshold && essence.state != EssenceState.Decaying) {
            essence.lastDecayCheckTime = block.timestamp; // Update check time even if no decay happens
            return;
        }

        // Calculate decay steps since last check, influenced by entropy
        uint256 decaySteps = timeSinceLastDecayCheck / (24 hours / (essence.entropy / entropyDecayFactor + 1)); // Example: higher entropy = faster decay

        if (decaySteps > 0) {
            uint256 energyLoss = decaySteps * energyDecayRate;
            uint256 coherenceLoss = decaySteps * coherenceDecayRate;
            uint256 entropyIncrease = decaySteps * 1; // Decay increases entropy

            uint256 lostEnergy = essence.energy > energyLoss ? energyLoss : essence.energy;
            uint256 lostCoherence = essence.coherence > coherenceLoss ? coherenceLoss : essence.coherence;

            essence.energy -= lostEnergy;
            essence.coherence -= lostCoherence;
            essence.entropy += entropyIncrease;

            // Change state to Decaying if not already
            if (essence.state != EssenceState.Decaying && essence.state != EssenceState.Entangled) { // Don't change state if entangled (entangled state takes precedence)
                 _changeState(tokenId, EssenceState.Decaying);
            }

            emit EssenceDecayed(tokenId, lostEnergy, lostCoherence, entropyIncrease);

            // If energy/coherence hits zero, maybe auto-burn?
            if (essence.energy == 0 && essence.coherence == 0) {
                // Only burn if not entangled - entangled decay might work differently
                 if (essence.state != EssenceState.Entangled) {
                     _burn(tokenId);
                 } else {
                     // Entangled but depleted: special state? Still Decaying but not burnt?
                 }
            }
            essence.lastDecayCheckTime = block.timestamp; // Update check time
        }
    }


    /// @notice Allows an essence meeting certain criteria to evolve to a new generation.
    /// Resets entropy and boosts potential, costs Flux and energy.
    /// @param tokenId The ID of the essence to evolve.
    function evolveEssence(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        if (!_exists(tokenId)) revert EssenceDoesNotExist();

        QuantumEssence storage essence = _essences[tokenId];

        // Define evolution conditions (example: min energy, min coherence, min age, not Decaying/Entangled)
        uint256 evolutionEnergyCost = essence.generation * 50; // Cost increases with generation
        uint256 evolutionFluxCost = essence.generation * 50;

        if (essence.energy < evolutionEnergyCost || essence.coherence < 80 || essence.entropy > 30 || essence.state == EssenceState.Decaying || essence.state == EssenceState.Entangled || (block.timestamp - essence.genesisTime) < 7 days * essence.generation) { // Age requirement increases with generation
             revert EvolutionConditionsNotMet();
        }

        if (_fluxBalances[msg.sender] < evolutionFluxCost) revert NotEnoughFlux();
         _fluxBalances[msg.sender] -= evolutionFluxCost;
        emit FluxPaid(msg.sender, evolutionFluxCost);


        // Apply evolution effects
        essence.energy -= evolutionEnergyCost; // Use energy for evolution
        essence.generation++;
        essence.entropy = 5; // Reset entropy
        essence.coherence += 20; // Boost base coherence potential

        // Change state
        _changeState(tokenId, EssenceState.Evolved);

        emit EssenceEvolved(tokenId, essence.generation);
    }

     /// @notice Allows a user to claim their accumulated Flux based on elapsed time.
     function claimFlux() public {
         uint256 lastClaim = _lastFluxClaimTime[msg.sender];
         uint256 timeElapsed = block.timestamp - lastClaim;
         uint256 claimableFlux = timeElapsed * fluxClaimRate;

         if (claimableFlux == 0) revert CannotClaimFluxYet();

         _fluxBalances[msg.sender] += claimableFlux;
         _lastFluxClaimTime[msg.sender] = block.timestamp;

         emit FluxClaimed(msg.sender, claimableFlux);
     }


    // --- View Functions ---

    /// @notice Returns the current state of a Quantum Essence.
    /// @param tokenId The ID of the essence.
    /// @return The state of the essence.
    function getEssenceState(uint256 tokenId) public view returns (EssenceState) {
        if (!_exists(tokenId)) revert EssenceDoesNotExist();
        return _essences[tokenId].state;
    }

    /// @notice Returns detailed properties of a Quantum Essence.
    /// @param tokenId The ID of the essence.
    /// @return energy, coherence, entropy, genesisTime, lastObservedTime, generation, state
    function getEssenceProperties(uint256 tokenId) public view returns (uint256 energy, uint256 coherence, uint256 entropy, uint256 genesisTime, uint256 lastObservedTime, uint256 generation, EssenceState state) {
         if (!_exists(tokenId)) revert EssenceDoesNotExist();
         QuantumEssence storage essence = _essences[tokenId];
         return (essence.energy, essence.coherence, essence.entropy, essence.genesisTime, essence.lastObservedTime, essence.generation, essence.state);
    }

    /// @notice Returns the IDs of essences currently entangled with the given one.
    /// @param tokenId The ID of the essence.
    /// @return An array of token IDs.
    function getLinkedEssences(uint256 tokenId) public view returns (uint256[] memory) {
         if (!_exists(tokenId)) revert EssenceDoesNotExist();
         return _essences[tokenId].linkedEssences;
    }

    /// @notice Returns the total number of Quantum Essences minted.
    /// @return The total count.
    function getTotalEssences() public view returns (uint256) {
        // Since we use _currentTokenId as a counter and it increments on minting,
        // and we don't reuse IDs on burn, _currentTokenId - 1 should be the last minted ID.
        // If we started at 1, _currentTokenId - 1 is the count. If started at 0, _currentTokenId is count.
        // Let's stick with _currentTokenId as the NEXT id, so count is _currentTokenId - 1 (if starting at 1).
        // Need to account for burnt tokens if we wanted a precise count of *existing* tokens.
        // For simplicity, let's return the total number of *minted* IDs.
        return _currentTokenId > 0 ? _currentTokenId - 1 : 0; // Assuming _currentTokenId starts at 1
    }

    /// @notice Returns the internal Flux balance for a given account.
    /// @param account The address to check.
    /// @return The Flux balance.
    function getFluxBalance(address account) public view returns (uint256) {
         return _fluxBalances[account];
    }

     /// @notice Returns the timestamp of the last Flux claim for an account.
     /// @param account The address to check.
     /// @return The timestamp.
    function getLastFluxClaimTime(address account) public view returns (uint256) {
         return _lastFluxClaimTime[account];
    }

     /// @notice Returns a list of token IDs owned by an address.
     /// @dev This function can be gas-intensive if an owner has many tokens.
     /// @param owner The address to query.
     /// @return An array of token IDs.
    function getEssencesByOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = _balances[owner];
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // Iterating through all possible IDs is inefficient if max ID is large.
        // A linked list or other pattern would be better for large collections,
        // but requires more complex storage. This is a simplified approach.
        // *** This implementation requires iterating through ALL minted tokens to find owner, which is highly inefficient and potentially exceeds block gas limit on chains like Ethereum mainnet if _currentTokenId is large. A better implementation would require a separate mapping or linked list structure. For this example, we keep it simple but inefficient. ***
        uint256 maxTokenId = _currentTokenId; // Check up to the latest minted ID
        for (uint256 i = 1; i < maxTokenId && index < tokenCount; i++) { // Assuming token IDs start from 1
            if (_exists(i) && _essences[i].owner == owner) {
                 tokenIds[index] = i;
                 index++;
            }
        }
        return tokenIds;
    }


    // --- Admin Functions ---

    /// @notice Owner-only: Sets the rate at which Flux can be claimed per second.
    /// @param ratePerSecond New rate.
    function adminSetFluxClaimRate(uint256 ratePerSecond) public onlyOwner {
        fluxClaimRate = ratePerSecond;
    }

    /// @notice Owner-only: Sets parameters controlling the decay process.
    /// @param observationThreshold_ Time (in seconds) after which decay begins if not observed.
    /// @param energyDecayRate_ Rate of energy loss per decay step.
    /// @param coherenceDecayRate_ Rate of coherence loss per decay step.
    function adminSetDecayParameters(uint256 observationThreshold_, uint256 energyDecayRate_, uint256 coherenceDecayRate_) public onlyOwner {
        observationDecayThreshold = observationThreshold_;
        energyDecayRate = energyDecayRate_;
        coherenceDecayRate = coherenceDecayRate_;
        // Could add setting entropyDecayFactor here too
    }

    /// @notice Owner-only: Sets the Flux cost for forging a new essence.
    /// @param cost The new Flux cost.
    function adminSetForgeCost(uint256 cost) public onlyOwner {
        forgeCost = cost;
    }

    /// @notice Owner-only: Recovers ERC20 tokens mistakenly sent to the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to rescue.
    function adminRescueFunds(address tokenAddress, uint256 amount) public onlyOwner {
        // Prevent rescuing this contract's internal Flux balance if it were an actual ERC20
        // As Flux is internal, this only applies to *other* ERC20 tokens.
        require(tokenAddress != address(this), "Cannot rescue internal Flux");
        // Standard ERC20 transfer out
        // This requires having the ERC20 interface and a contract address for the token
        // Example using a placeholder interface:
        // IERC20(tokenAddress).transfer(owner, amount);
    }


    // --- Internal Helpers ---

    /// @dev Changes the state of an essence and emits the event.
    /// @param tokenId The ID of the essence.
    /// @param newState The state to transition to.
    function _changeState(uint256 tokenId, EssenceState newState) internal {
        QuantumEssence storage essence = _essences[tokenId];
        if (essence.state != newState) {
             EssenceState oldState = essence.state;
             essence.state = newState;
             emit StateChanged(tokenId, oldState, newState);
        }
    }

    /// @dev Assesses if an essence's state should change based on its current properties (energy, coherence, entropy).
    /// @param tokenId The ID of the essence.
    function _assessStateChange(uint256 tokenId) internal {
        QuantumEssence storage essence = _essences[tokenId];
        // Don't override Entangled or Evolved state with simple property changes
        if (essence.state == EssenceState.Entangled || essence.state == EssenceState.Evolved) return;

        if (essence.entropy > 50 && essence.coherence < 30 && essence.state != EssenceState.Decaying) {
            // High entropy, low coherence suggests volatility or decay potential
            // If not Decaying, might become Volatile
             if (essence.state != EssenceState.Volatile) {
                 _changeState(tokenId, EssenceState.Volatile);
             }
        } else if (essence.coherence > 80 && essence.entropy < 10 && essence.state != EssenceState.Stable) {
            // High coherence, low entropy suggests stability
             if (essence.state != EssenceState.Volatile && essence.state != EssenceState.Decaying) { // Only transition from non-critical states
                  _changeState(tokenId, EssenceState.Stable);
             }
        } else if (essence.energy == 0 && essence.coherence == 0 && essence.state != EssenceState.Decaying) {
            // Depleted state might lead to decay
             _changeState(tokenId, EssenceState.Decaying);
        }
         // Decay state is primarily managed by the _applyDecay function
    }


    /// @dev Internal helper to check if two essences are linked.
    /// @param tokenId1 The first essence ID.
    /// @param tokenId2 The second essence ID.
    /// @return True if linked, false otherwise.
    function _isLinked(uint256 tokenId1, uint256 tokenId2) internal view returns (bool) {
        QuantumEssence storage essence1 = _essences[tokenId1];
        for (uint256 i = 0; i < essence1.linkedEssences.length; i++) {
            if (essence1.linkedEssences[i] == tokenId2) {
                 return true;
            }
        }
        return false;
    }

    /// @dev Internal helper to remove a link from an essence's linked list.
    /// @param tokenId The essence ID whose link list is modified.
    /// @param linkToRemove The essence ID to remove from the list.
    function _removeLink(uint256 tokenId, uint256 linkToRemove) internal {
        QuantumEssence storage essence = _essences[tokenId];
        uint256[] storage linked = essence.linkedEssences;
        for (uint256 i = 0; i < linked.length; i++) {
            if (linked[i] == linkToRemove) {
                 // Swap with last element and pop
                 linked[i] = linked[linked.length - 1];
                 linked.pop();
                 break; // Assuming only one link between two essences
            }
        }
    }

    /// @dev Propagates a simplified "observation" or "interaction" effect to entangled partners.
    /// Effects could include slight energy/coherence loss, minor entropy increase, or probabilistic state change.
    /// @param tokenId The ID of the essence that was observed/interacted with.
    /// @param intensity A value indicating the strength of the propagation (e.g., higher for combine/split).
    function _propagateEntanglement(uint256 tokenId, uint256 intensity) internal {
         QuantumEssence storage essence = _essences[tokenId];
         uint256[] memory linked = essence.linkedEssences; // Get a memory copy to avoid re-entrancy issues if partner calls back (unlikely here)

         uint256 effect = intensity * 5; // Example: propagation effect scale

         for (uint256 i = 0; i < linked.length; i++) {
             uint256 partnerId = linked[i];
             if (_exists(partnerId)) {
                  QuantumEssence storage partner = _essences[partnerId];
                  // Apply minor effects to partner
                  partner.energy = partner.energy > effect ? partner.energy - effect : 0;
                  partner.coherence = partner.coherence > effect ? partner.coherence - effect : 0;
                  partner.entropy += effect / 2; // Minor entropy increase

                  // Probabilistic state change for partner based on its own stats and propagated effect
                  uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, partnerId, essence.tokenId, effect))) % 1000;
                  uint256 volatilityChance = (partner.entropy * 50) / (partner.coherence + 1) + intensity * 10; // Entropy/coherence + propagation intensity influence

                  if (randomFactor < volatilityChance && partner.state != EssenceState.Volatile && partner.state != EssenceState.Decaying) {
                      // Only change state if not already volatile or decaying, and the partner isn't the one triggering the original event
                      _changeState(partnerId, EssenceState.Volatile);
                  }
                  // Recursively propagate? Or just one level? Let's do one level to avoid infinite loops.
                  // If a partner is also entangled with others, their states might be affected, but this function only handles the direct link.
             }
         }
    }

    // --- Receive Ether (optional, typically not needed for pure token contracts) ---
    // Add if the contract should be able to receive Ether (e.g., for buying Flux)
    // receive() external payable {}
}
```