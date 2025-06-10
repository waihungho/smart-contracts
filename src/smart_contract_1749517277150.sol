Okay, this is an exciting challenge! Let's design a smart contract that goes beyond standard tokens or simple NFTs. We'll create a system involving "Quantum Particles" which have both a fungible "Energy" component and a non-fungible "State" component, with the key concept being "Entanglement" that links pairs of particles and allows for unique interactions and state changes.

This contract will simulate concepts like state correlation, decay, entanglement effects, and synthesis, integrating ERC-20-like (Energy) and ERC-721-like (Particle State) functionalities with custom logic.

**Disclaimer:** This contract uses simulated quantum concepts for creative flair. The randomness simulation (`block.timestamp`, `block.difficulty`, `keccak256`) is *not* cryptographically secure and can be manipulated by miners. True randomness on-chain is hard and requires oracles (like Chainlink VRF). This is a conceptual example. Also, complex state management and loops can incur significant gas costs. This is for demonstration and learning purposes, not production-ready without significant security audits and gas optimizations.

---

### QuantumEntanglementToken (QET) - Contract Outline & Function Summary

**Contract Name:** `QuantumEntanglementToken`

**Concept:** Simulates a system of "Quantum Particles". Each particle has a unique ID, an owner, a dynamic internal "State", and is associated with a fungible quantity of "Energy". Particles can be "Entangled" in pairs, causing actions on one to potentially affect the other. Particle states can also change based on time (Decay) or simulated quantum fluctuations.

**Core Features:**

1.  **Hybrid Fungible/Non-Fungible:** Manages both fungible Energy (like ERC-20) and non-fungible Particle States (like ERC-721).
2.  **Dynamic Particle State:** Particles have attributes (represented by a `stateValue`) that can change over time or through specific actions.
3.  **Entanglement:** Allows linking two specific Particle IDs. Entangled pairs share a unique relationship.
4.  **Entanglement Effects:** Specific functions operate only on entangled pairs, influencing their states or allowing unique Energy transfers.
5.  **Time-Based Decay:** Particle states can degrade over time unless they have specific properties.
6.  **Synthesis:** Combining Energy and particles to create new particles.
7.  **Delegation:** Owners can delegate specific actions on their particles.
8.  **Probabilistic Events:** Simulated "Quantum Fluctuations" and some entanglement effects involve pseudo-randomness.

**Function Categories & Summary (Target: 20+ functions):**

*   **Energy (ERC-20 inspired):**
    *   `totalSupplyEnergy()`: Get total fungible Energy supply.
    *   `balanceOfEnergy(address account)`: Get Energy balance of an address.
    *   `transferEnergy(address recipient, uint256 amount)`: Transfer Energy.
    *   `approveEnergy(address spender, uint256 amount)`: Approve spender for Energy.
    *   `allowanceEnergy(address owner, address spender)`: Get Energy allowance.
    *   `transferEnergyFrom(address sender, address recipient, uint256 amount)`: Transfer Energy using allowance.
    *   `batchTransferEnergy(address[] recipients, uint256[] amounts)`: Transfer Energy to multiple recipients.

*   **Particle (ERC-721 inspired - Focus on State Ownership):**
    *   `createParticle()`: Mint a new particle with an initial state.
    *   `ownerOfParticle(uint256 particleId)`: Get owner of a particle ID.
    *   `balanceOfParticles(address owner)`: Get count of particles owned by an address.
    *   `transferParticleState(address from, address to, uint256 particleId)`: Transfer ownership/control of a particle ID and its state.
    *   `approveParticleState(address to, uint256 particleId)`: Approve an address to transfer a specific particle state.
    *   `getApprovedParticleState(uint256 particleId)`: Get approved address for a particle state.
    *   `setApprovalForAllParticleStates(address operator, bool approved)`: Set operator approval for all particle states.
    *   `isApprovedForAllParticleStates(address owner, address operator)`: Check operator approval status.
    *   `batchCreateParticles(uint256 count)`: Mint multiple particles.

*   **Particle State & Dynamics:**
    *   `getParticleState(uint256 particleId)`: Read particle state attributes.
    *   `applyQuantumFluctuation(uint256 particleId)`: Apply a probabilistic change to a particle's state (simulated).
    *   `applyStateDecay(uint256 particleId)`: Apply time-based state decay.
    *   `synthesizeParticle(uint256 baseParticleId, uint256 energyCost)`: Create a new particle using Energy and a base particle.
    *   `configureParticleBehavior(uint256 particleId, bool decayResistance)`: Modify specific behaviors for a particle (e.g., toggle decay resistance).
    *   `getParticleAge(uint256 particleId)`: Get the age of a particle.

*   **Entanglement Management:**
    *   `requestEntanglement(uint256 particleId1, uint256 particleId2)`: Initiate an entanglement request between two particles (owned by potentially different users).
    *   `acceptEntanglement(uint256 particleId1, uint256 particleId2)`: Accept an entanglement request.
    *   `breakEntanglement(uint256 particleId)`: Sever the entanglement link for a particle (also breaks for its pair).
    *   `isEntangled(uint256 particleId)`: Check if a particle is entangled.
    *   `getEntangledPair(uint256 particleId)`: Get the ID of the particle entangled with the given one.
    *   `probeEntanglementStability(uint256 particleId)`: Get the duration of the current entanglement link.

*   **Entanglement Actions:**
    *   `transferEnergyViaEntanglement(uint256 particleId, uint256 amount)`: Transfer Energy *between the owners* of entangled particles via their link.
    *   `collapseEntangledStates(uint256 particleId)`: Deterministically change the states of an entangled pair based on their current combined state (simulated).
    *   `induceStateCorrelation(uint256 particleId, uint8 targetValue)`: Attempt to probabilistically make the states of an entangled pair converge towards a target value.
    *   `disentangleAndMergeEnergy(uint256 particleId)`: Break entanglement and merge the Energy balances of the two particle owners into one (complex, maybe transfer to a third). Let's simplify: break entanglement and potentially give a bonus/penalty. Or simpler: break entanglement and transfer Energy from one owner to the other based on some rule. Let's make it transfer energy based on state difference upon disentanglement.

*   **Delegation:**
    *   `grantParticleActionDelegate(uint256 particleId, address delegatee)`: Allow an address to perform certain actions (like state changes, entanglement actions) on a specific particle.
    *   `revokeParticleActionDelegate(uint256 particleId, address delegatee)`: Revoke delegation.
    *   `isParticleActionDelegate(uint256 particleId, address delegatee)`: Check delegation status.

*   **Admin/Utility:**
    *   `pauseEntanglement(bool paused)`: Pause entanglement requests/actions (admin only).
    *   `setEntanglementStabilityBonusFactor(uint256 factor)`: Set a parameter affecting entanglement actions (admin only).

**Total Functions (approx):** 7 (Energy) + 9 (Particle Basic) + 6 (State/Dynamics) + 6 (Entanglement Management) + 4 (Entanglement Actions) + 3 (Delegation) + 2 (Admin) = **37 functions** (including constructor implicitly). Easily exceeds 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementToken (QET)
 * @dev A smart contract simulating a system of "Quantum Particles" with
 *      hybrid fungible (Energy) and non-fungible (Particle State) components,
 *      featuring dynamic states and particle "Entanglement".
 *      NOTE: Uses pseudo-randomness for simulation, which is not cryptographically secure.
 *      Not audited for production use.
 */

/*
 * CONTRACT OUTLINE & FUNCTION SUMMARY
 *
 * Concept: Manages Quantum Particles, each with unique ID, owner, dynamic state,
 *          and associated fungible Energy. Particles can be entangled in pairs.
 *
 * Core Features:
 *  - Hybrid ERC-20 (Energy) / ERC-721 (Particle State) inspired functionalities.
 *  - Dynamic & Time-Dependent Particle State (Decay, Fluctuation).
 *  - Particle Entanglement & Pair-Specific Actions.
 *  - Synthesis of new particles.
 *  - Action Delegation per particle.
 *  - Simulated Probabilistic Events.
 *
 * Function Categories:
 *
 * 1. Energy (Fungible, ERC-20 Inspired):
 *    - totalSupplyEnergy()
 *    - balanceOfEnergy(address account)
 *    - transferEnergy(address recipient, uint256 amount)
 *    - approveEnergy(address spender, uint256 amount)
 *    - allowanceEnergy(address owner, address spender)
 *    - transferEnergyFrom(address sender, address recipient, uint256 amount)
 *    - batchTransferEnergy(address[] recipients, uint256[] amounts)
 *
 * 2. Particle (Non-Fungible, ERC-721 Inspired State Ownership):
 *    - createParticle()
 *    - ownerOfParticle(uint256 particleId)
 *    - balanceOfParticles(address owner)
 *    - transferParticleState(address from, address to, uint256 particleId)
 *    - approveParticleState(address to, uint256 particleId)
 *    - getApprovedParticleState(uint256 particleId)
 *    - setApprovalForAllParticleStates(address operator, bool approved)
 *    - isApprovedForAllParticleStates(address owner, address operator)
 *    - batchCreateParticles(uint256 count)
 *
 * 3. Particle State & Dynamics:
 *    - getParticleState(uint256 particleId)
 *    - applyQuantumFluctuation(uint256 particleId)
 *    - applyStateDecay(uint256 particleId)
 *    - synthesizeParticle(uint256 baseParticleId, uint256 energyCost)
 *    - configureParticleBehavior(uint256 particleId, bool decayResistance)
 *    - getParticleAge(uint256 particleId)
 *
 * 4. Entanglement Management:
 *    - requestEntanglement(uint256 particleId1, uint256 particleId2)
 *    - acceptEntanglement(uint256 particleId1, uint256 particleId2)
 *    - breakEntanglement(uint256 particleId)
 *    - isEntangled(uint256 particleId)
 *    - getEntangledPair(uint256 particleId)
 *    - probeEntanglementStability(uint256 particleId)
 *
 * 5. Entanglement Actions:
 *    - transferEnergyViaEntanglement(uint256 particleId, uint256 amount)
 *    - collapseEntangledStates(uint256 particleId)
 *    - induceStateCorrelation(uint256 particleId, uint8 targetValue)
 *    - disentangleAndTransferEnergy(uint256 particleId)
 *
 * 6. Delegation:
 *    - grantParticleActionDelegate(uint256 particleId, address delegatee)
 *    - revokeParticleActionDelegate(uint256 particleId, address delegatee)
 *    - isParticleActionDelegate(uint256 particleId, address delegatee)
 *
 * 7. Admin & Utility:
 *    - pauseEntanglement(bool paused)
 *    - setEntanglementStabilityBonusFactor(uint256 factor)
 */

contract QuantumEntanglementToken {

    // --- State Variables ---

    // Admin/Owner
    address public owner;

    // Energy (Fungible, ERC-20 inspired)
    mapping(address => uint256) private _energyBalances;
    mapping(address => mapping(address => uint256)) private _energyAllowances;
    uint256 private _totalSupplyEnergy;

    // Particle (Non-Fungible State Ownership, ERC-721 inspired)
    mapping(uint256 => address) private _particleOwners;
    mapping(address => uint256) private _particleCount;
    mapping(uint256 => address) private _particleStateApprovals;
    mapping(address => mapping(address => bool)) private _particleOperatorApprovals;
    uint256 private _nextTokenId; // Counter for unique particle IDs

    // Particle State & Dynamics
    struct ParticleState {
        uint8 stateValue;             // A numerical representation of the state (0-255)
        uint64 creationTimestamp;    // When the particle was created
        uint64 lastStateChangeTimestamp; // When the state last changed
        bool decayResistance;         // Does this particle resist decay?
        // Add more attributes here as needed (e.g., color, temperature, etc.)
    }
    mapping(uint256 => ParticleState) private _particleStates;

    // Entanglement
    mapping(uint256 => uint256) private _entangledPairs; // particleId => entangledParticleId
    mapping(uint256 => uint64) private _entanglementTimestamp; // particleId => timestamp of entanglement start
    mapping(uint256 => uint256) private _entanglementRequests; // requesterParticleId => targetParticleId (for entanglement requests)
    bool public entanglementPaused = false; // Admin control

    // Delegation
    // particleId => delegatee address => isApproved
    mapping(uint256 => mapping(address => bool)) private _particleActionDelegates;

    // Admin parameters
    uint256 public entanglementStabilityBonusFactor = 1; // Parameter for bonus/penalty in disentangle logic etc. (example)
    uint256 public constant STATE_DECAY_INTERVAL = 1 days; // How often decay can be applied per particle
    uint8 public constant STATE_DECAY_AMOUNT = 1; // Amount state decays per interval


    // --- Events ---

    // Energy Events (ERC-20 standard)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Particle Events (ERC-721 inspired)
    event ParticleCreated(address indexed owner, uint256 indexed particleId);
    event ParticleStateTransfer(address indexed from, address indexed to, uint256 indexed particleId); // Ownership transfer
    event ApprovalParticleState(address indexed owner, address indexed approved, uint256 indexed particleId);
    event ApprovalForAllParticleStates(address indexed owner, address indexed operator, bool approved);

    // Particle State & Dynamics Events
    event ParticleStateChanged(uint256 indexed particleId, uint8 oldState, uint8 newState, string reason);
    event ParticleSynthesized(address indexed owner, uint256 indexed newParticleId, uint265 indexed baseParticleId, uint256 energyCost);

    // Entanglement Events
    event EntanglementRequested(uint256 indexed particleId1, uint256 indexed particleId2, address indexed requester);
    event EntanglementAccepted(uint256 indexed particleId1, uint256 indexed particleId2);
    event EntanglementBroken(uint256 indexed particleId1, uint256 indexed particleId2);

    // Delegation Events
    event ParticleActionDelegateGranted(uint256 indexed particleId, address indexed owner, address indexed delegatee);
    event ParticleActionDelegateRevoked(uint256 indexed particleId, address indexed owner, address indexed delegatee);


    // --- Errors ---

    error NotOwnerOrApproved();
    error NotOwnerOrDelegate();
    error InvalidAmount();
    error InvalidRecipient();
    error NotEnoughEnergy(uint256 requested, uint256 available);
    error ApprovalNeeded(address spender, uint256 requested, uint256 available);
    error ParticleDoesNotExist(uint256 particleId);
    error NotParticleOwner(address sender, uint256 particleId);
    error ParticleAlreadyOwned(uint256 particleId, address currentOwner);
    error SelfTransferNotAllowed();
    error InvalidParticleId();
    error EntanglementPaused();
    error ParticlesAlreadyEntangled(uint256 particleId1, uint256 particleId2);
    error ParticlesMustBeDifferent();
    error EntanglementRequestNotFound(uint256 particleId1, uint256 particleId2);
    error NotEntangled(uint256 particleId);
    error NotDelegate(address delegatee, uint256 particleId);
    error NotEnoughParticles(uint256 required, uint256 available);
    error BatchLengthMismatch();
    error StateDecayRecentlyApplied(uint256 particleId, uint64 lastApplied);
    error EntangledEnergyTransferRequiresEntanglement();


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerOrApproved(); // Reusing error for simplicity
        _;
    }

    modifier onlyParticleOwnerOrApproved(uint256 particleId) {
        if (_isApprovedOrOwnerParticle(msg.sender, particleId)) {
            _;
        } else {
            revert NotOwnerOrApproved();
        }
    }

    modifier onlyParticleOwnerOrDelegate(uint256 particleId) {
        if (_particleOwners[particleId] == msg.sender || _particleActionDelegates[particleId][msg.sender]) {
            _;
        } else {
            revert NotOwnerOrDelegate();
        }
    }

    modifier whenEntanglementNotPaused() {
        if (entanglementPaused) revert EntanglementPaused();
        _;
    }


    // --- Internal Helpers ---

    /**
     * @dev Generates a pseudo-random seed. NOT SECURE.
     */
    function _getPseudoRandomSeed() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }

    /**
     * @dev Mints Energy tokens.
     */
    function _mintEnergy(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidRecipient();
        _totalSupplyEnergy += amount;
        _energyBalances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Burns Energy tokens.
     */
    function _burnEnergy(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidRecipient();
        if (_energyBalances[account] < amount) revert NotEnoughEnergy(amount, _energyBalances[account]);
        _energyBalances[account] -= amount;
        _totalSupplyEnergy -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Transfers Energy tokens.
     */
    function _transferEnergy(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0)) revert InvalidRecipient();
        if (_energyBalances[sender] < amount) revert NotEnoughEnergy(amount, _energyBalances[sender]);

        _energyBalances[sender] -= amount;
        _energyBalances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Mints a new particle and assigns initial state.
     */
    function _createParticle(address initialOwner) internal returns (uint256) {
        uint256 newParticleId = _nextTokenId++;
        _particleOwners[newParticleId] = initialOwner;
        _particleCount[initialOwner]++;

        // Simulate initial state based on pseudo-randomness
        uint256 seed = _getPseudoRandomSeed();
        uint8 initialState = uint8(seed % 101); // State between 0 and 100

        _particleStates[newParticleId] = ParticleState({
            stateValue: initialState,
            creationTimestamp: uint64(block.timestamp),
            lastStateChangeTimestamp: uint64(block.timestamp),
            decayResistance: (seed % 10) == 0 // 10% chance of initial decay resistance
        });

        emit ParticleCreated(initialOwner, newParticleId);
        emit ParticleStateChanged(newParticleId, 0, initialState, "Creation"); // Old state 0 conceptually
        return newParticleId;
    }

    /**
     * @dev Internal function to check if an address is authorized for a particle.
     */
    function _isApprovedOrOwnerParticle(address spender, uint256 particleId) internal view returns (bool) {
        address owner_ = _particleOwners[particleId];
        return (spender == owner_ || _particleStateApprovals[particleId] == spender || _particleOperatorApprovals[owner_][spender]);
    }

    /**
     * @dev Internal function to transfer particle state ownership.
     */
    function _transferParticleState(address from, address to, uint256 particleId) internal {
        if (from == address(0) || to == address(0)) revert InvalidRecipient();
        if (_particleOwners[particleId] != from) revert NotParticleOwner(from, particleId);
        if (from == to) revert SelfTransferNotAllowed();
        if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId); // Should not happen if owner check passes

        // Break entanglement if transferring an entangled particle
        if (_entangledPairs[particleId] != 0) {
            _breakEntanglement(particleId); // This also breaks for the other particle
        }

        // Clear approvals
        delete _particleStateApprovals[particleId];
        // Clear delegates (optional, maybe delegation persists with the particle?)
        // Decide whether delegates transfer with ownership. For this example, let's clear.
        // Note: Clearing mapping values is complex. Let's skip clearing delegates for simplicity,
        // but document that delegates remain until revoked by the *new* owner or the original granter.
        // A cleaner approach might store delegates in a struct/array per particle.

        _particleCount[from]--;
        _particleOwners[particleId] = to;
        _particleCount[to]++;

        emit ParticleStateTransfer(from, to, particleId);
    }

    /**
     * @dev Internal helper to update particle state and emit event.
     */
    function _updateParticleState(uint256 particleId, uint8 newStateValue, string memory reason) internal {
         ParticleState storage particle = _particleStates[particleId];
         uint8 oldStateValue = particle.stateValue;
         if (oldStateValue != newStateValue) {
             particle.stateValue = newStateValue;
             particle.lastStateChangeTimestamp = uint64(block.timestamp);
             emit ParticleStateChanged(particleId, oldStateValue, newStateValue, reason);
         }
    }

    /**
     * @dev Internal helper to break entanglement.
     */
    function _breakEntanglement(uint256 particleId) internal {
        uint256 entangledId = _entangledPairs[particleId];
        if (entangledId == 0) {
             // Already not entangled, or invalid ID
             return;
        }

        delete _entangledPairs[particleId];
        delete _entanglementTimestamp[particleId];

        if (_entangledPairs[entangledId] == particleId) { // Ensure the reverse link exists
            delete _entangledPairs[entangledId];
            delete _entanglementTimestamp[entangledId];
        }

        emit EntanglementBroken(particleId, entangledId);
    }


    // --- Energy Functions (ERC-20 inspired) ---

    /**
     * @dev Returns the total supply of Energy tokens.
     */
    function totalSupplyEnergy() external view returns (uint256) {
        return _totalSupplyEnergy;
    }

    /**
     * @dev Returns the Energy balance of a specific account.
     */
    function balanceOfEnergy(address account) external view returns (uint256) {
        return _energyBalances[account];
    }

    /**
     * @dev Transfers Energy tokens from the caller's account to a recipient.
     */
    function transferEnergy(address recipient, uint256 amount) external returns (bool) {
        _transferEnergy(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approves a spender to withdraw a specified amount of Energy from the caller.
     */
    function approveEnergy(address spender, uint256 amount) external returns (bool) {
        _energyAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Returns the remaining amount of Energy that spender will be allowed to spend on behalf of owner.
     */
    function allowanceEnergy(address owner_, address spender) external view returns (uint256) {
        return _energyAllowances[owner_][spender];
    }

    /**
     * @dev Transfers Energy from a sender account to a recipient account using the caller's allowance.
     */
    function transferEnergyFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _energyAllowances[sender][msg.sender];
        if (currentAllowance < amount) revert ApprovalNeeded(msg.sender, amount, currentAllowance);

        unchecked {
            _energyAllowances[sender][msg.sender] = currentAllowance - amount;
        }
        _transferEnergy(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Transfers Energy to multiple recipients in a single transaction.
     * @param recipients Array of recipient addresses.
     * @param amounts Array of amounts corresponding to recipients.
     */
    function batchTransferEnergy(address[] calldata recipients, uint256[] calldata amounts) external {
        if (recipients.length != amounts.length) revert BatchLengthMismatch();
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        if (_energyBalances[msg.sender] < totalAmount) revert NotEnoughEnergy(totalAmount, _energyBalances[msg.sender]);

        for (uint i = 0; i < recipients.length; i++) {
            _transferEnergy(msg.sender, recipients[i], amounts[i]);
        }
    }


    // --- Particle Functions (ERC-721 inspired State Ownership) ---

    /**
     * @dev Creates a new Quantum Particle and assigns ownership to the caller.
     * @return particleId The ID of the newly created particle.
     */
    function createParticle() external returns (uint256) {
        return _createParticle(msg.sender);
    }

    /**
     * @dev Returns the owner of a specific particle ID.
     */
    function ownerOfParticle(uint256 particleId) external view returns (address) {
        address owner_ = _particleOwners[particleId];
        if (owner_ == address(0)) revert ParticleDoesNotExist(particleId);
        return owner_;
    }

    /**
     * @dev Returns the number of particles owned by an address.
     */
    function balanceOfParticles(address owner_) external view returns (uint256) {
        if (owner_ == address(0)) revert InvalidRecipient();
        return _particleCount[owner_];
    }

     /**
     * @dev Transfers ownership/control of a Particle ID and its state from one address to another.
     * @param from The current owner.
     * @param to The new owner.
     * @param particleId The particle ID to transfer.
     */
    function transferParticleState(address from, address to, uint256 particleId) external {
        // ERC721 standard check: caller must be owner, approved for particle, or approved for all
        if (!_isApprovedOrOwnerParticle(msg.sender, particleId)) revert NotOwnerOrApproved();

        _transferParticleState(from, to, particleId);
    }

    /**
     * @dev Approves another address to transfer a specific particle's state.
     */
    function approveParticleState(address to, uint256 particleId) external {
        address owner_ = _particleOwners[particleId];
        if (owner_ == address(0)) revert ParticleDoesNotExist(particleId);
        if (msg.sender != owner_ && !_particleOperatorApprovals[owner_][msg.sender]) revert NotOwnerOrApproved();
        if (to == owner_) revert SelfTransferNotAllowed(); // Cannot approve self

        _particleStateApprovals[particleId] = to;
        emit ApprovalParticleState(owner_, to, particleId);
    }

     /**
     * @dev Gets the approved address for a single particle ID.
     */
    function getApprovedParticleState(uint256 particleId) external view returns (address) {
         if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
         return _particleStateApprovals[particleId];
    }


    /**
     * @dev Sets or unsets the approval of an operator to manage all of the caller's particles.
     */
    function setApprovalForAllParticleStates(address operator, bool approved) external {
        if (operator == msg.sender) revert SelfTransferNotAllowed(); // Cannot approve self as operator
        _particleOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAllParticleStates(msg.sender, operator, approved);
    }

    /**
     * @dev Queries if an address is an authorized operator for another address.
     */
    function isApprovedForAllParticleStates(address owner_, address operator) external view returns (bool) {
        return _particleOperatorApprovals[owner_][operator];
    }

     /**
     * @dev Creates multiple new Quantum Particles and assigns ownership to the caller.
     * @param count The number of particles to create.
     */
    function batchCreateParticles(uint256 count) external {
        for (uint i = 0; i < count; i++) {
            _createParticle(msg.sender);
        }
    }


    // --- Particle State & Dynamics ---

    /**
     * @dev Returns the current state and other attributes of a particle.
     */
    function getParticleState(uint256 particleId) external view returns (ParticleState memory) {
        if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
        return _particleStates[particleId];
    }

    /**
     * @dev Applies a simulated quantum fluctuation, potentially changing the particle's state randomly.
     *      Only the owner or a delegate can trigger this.
     */
    function applyQuantumFluctuation(uint256 particleId) external onlyParticleOwnerOrDelegate(particleId) {
        if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);

        uint256 seed = _getPseudoRandomSeed();
        uint8 fluctuationAmount = uint8(seed % 21); // Simulate a random change amount (0-20)
        bool increase = (seed % 2) == 0; // Simulate random direction (increase/decrease)

        ParticleState storage particle = _particleStates[particleId];
        uint8 currentState = particle.stateValue;
        uint8 newState;

        if (increase) {
             newState = currentState + fluctuationAmount;
             // Cap at 255
             if (newState < currentState) newState = 255; // Handle overflow wrap-around
        } else {
            newState = currentState - fluctuationAmount;
             // Floor at 0
            if (newState > currentState) newState = 0; // Handle underflow wrap-around
        }

        _updateParticleState(particleId, newState, "Quantum Fluctuation");
    }

    /**
     * @dev Applies time-based decay to a particle's state if it's not decay-resistant and sufficient time has passed.
     *      Can be triggered by anyone, but only affects the state if conditions are met.
     *      This encourages users/systems to "maintain" particles.
     */
    function applyStateDecay(uint256 particleId) external {
        ParticleState storage particle = _particleStates[particleId];
        if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId); // Check particle exists

        if (particle.decayResistance) {
            // Particle is resistant, no decay
            return;
        }

        uint64 timeSinceLastChange = uint64(block.timestamp) - particle.lastStateChangeTimestamp;
        uint256 decayIntervals = timeSinceLastChange / STATE_DECAY_INTERVAL;

        if (decayIntervals == 0) {
            // Not enough time has passed since last change/decay application
            revert StateDecayRecentlyApplied(particleId, particle.lastStateChangeTimestamp);
        }

        uint8 decayAmount = uint8(decayIntervals * STATE_DECAY_AMOUNT);
        uint8 currentState = particle.stateValue;
        uint8 newState = currentState > decayAmount ? currentState - decayAmount : 0;

        if (newState < currentState) { // Only update if decay actually occurs
            _updateParticleState(particleId, newState, "Time Decay");
        }
    }

    /**
     * @dev Synthesizes a new particle by consuming Energy and leveraging a base particle.
     *      The base particle's state might influence the new particle's initial state.
     *      Owner of the base particle performs the synthesis.
     */
    function synthesizeParticle(uint256 baseParticleId, uint256 energyCost) external onlyParticleOwnerOrApproved(baseParticleId) {
         address baseOwner = _particleOwners[baseParticleId];
         if (baseOwner == address(0)) revert ParticleDoesNotExist(baseParticleId);

         _burnEnergy(baseOwner, energyCost);

         uint256 newParticleId = _createParticle(baseOwner); // New particle initially owned by base owner

         // Simulate influence from the base particle
         ParticleState storage baseState = _particleStates[baseParticleId];
         ParticleState storage newParticleState = _particleStates[newParticleId];

         // Example influence: new state is average of base state and initial random state
         newParticleState.stateValue = uint8((uint256(newParticleState.stateValue) + baseState.stateValue) / 2);
         // New particle inherits decay resistance from base particle with some probability
         if (baseState.decayResistance && (_getPseudoRandomSeed() % 2) == 0) {
              newParticleState.decayResistance = true;
         }

         emit ParticleSynthesized(baseOwner, newParticleId, baseParticleId, energyCost);
         emit ParticleStateChanged(newParticleId, newParticleState.stateValue, newParticleState.stateValue, "Synthesis Influence"); // Reflect synthesis influence

    }

     /**
     * @dev Configures behavioral parameters for a specific particle.
     *      Only the owner or a delegate can perform this.
     */
    function configureParticleBehavior(uint256 particleId, bool decayResistance) external onlyParticleOwnerOrDelegate(particleId) {
        if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
        _particleStates[particleId].decayResistance = decayResistance;
         // No event needed unless we want to track config changes explicitly
    }

    /**
     * @dev Gets the age of a particle in seconds since creation.
     */
    function getParticleAge(uint256 particleId) external view returns (uint256) {
        if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
        return uint256(block.timestamp) - _particleStates[particleId].creationTimestamp;
    }


    // --- Entanglement Management ---

    /**
     * @dev Requests entanglement between two particles. Both particles must exist.
     *      The owner of particleId1 must initiate, requesting entanglement with particleId2.
     *      The owner of particleId2 must then accept.
     */
    function requestEntanglement(uint256 particleId1, uint256 particleId2) external onlyParticleOwnerOrDelegate(particleId1) whenEntanglementNotPaused {
        if (_particleOwners[particleId1] == address(0)) revert ParticleDoesNotExist(particleId1);
        if (_particleOwners[particleId2] == address(0)) revert ParticleDoesNotExist(particleId2);
        if (particleId1 == particleId2) revert ParticlesMustBeDifferent();
        if (_entangledPairs[particleId1] != 0 || _entangledPairs[particleId2] != 0) revert ParticlesAlreadyEntangled(particleId1, particleId2);

        // Store request: particle1 owner requesting entanglement with particle2 owned by someone else
        _entanglementRequests[particleId1] = particleId2;

        emit EntanglementRequested(particleId1, particleId2, msg.sender);
    }

    /**
     * @dev Accepts an entanglement request. The caller must be the owner (or delegate)
     *      of the particle that was the target of the request.
     */
    function acceptEntanglement(uint256 particleId1, uint256 particleId2) external onlyParticleOwnerOrDelegate(particleId2) whenEntanglementNotPaused {
        if (_particleOwners[particleId1] == address(0)) revert ParticleDoesNotExist(particleId1);
        if (_particleOwners[particleId2] == address(0)) revert ParticleDoesNotExist(particleId2);
         if (particleId1 == particleId2) revert ParticlesMustBeDifferent();

        // Check if a valid request exists where particleId2 was the target and particleId1 was the source
        if (_entanglementRequests[particleId1] != particleId2) revert EntanglementRequestNotFound(particleId1, particleId2);

        // Clear the request now that it's accepted
        delete _entanglementRequests[particleId1];

        // Establish bidirectional entanglement
        _entangledPairs[particleId1] = particleId2;
        _entangledPairs[particleId2] = particleId1;
        _entanglementTimestamp[particleId1] = uint64(block.timestamp);
        _entanglementTimestamp[particleId2] = uint64(block.timestamp);

        emit EntanglementAccepted(particleId1, particleId2);
    }

    /**
     * @dev Breaks the entanglement link for a particle pair.
     *      Can be triggered by the owner (or delegate) of either entangled particle.
     */
    function breakEntanglement(uint256 particleId) external onlyParticleOwnerOrDelegate(particleId) {
        if (_entangledPairs[particleId] == 0) revert NotEntangled(particleId);
        _breakEntanglement(particleId);
    }

    /**
     * @dev Checks if a particle is currently entangled.
     */
    function isEntangled(uint256 particleId) external view returns (bool) {
        // Check if particle exists implicitly by checking entanglement status
        return _entangledPairs[particleId] != 0;
    }

    /**
     * @dev Returns the ID of the particle entangled with the given one. Returns 0 if not entangled.
     */
    function getEntangledPair(uint256 particleId) external view returns (uint256) {
        // No need to check if particle exists, returning 0 is informative
        return _entangledPairs[particleId];
    }

     /**
     * @dev Gets the duration (in seconds) that a particle has been entangled. Returns 0 if not entangled.
     */
    function probeEntanglementStability(uint256 particleId) external view returns (uint256) {
        if (_entangledPairs[particleId] == 0) return 0; // Not entangled
        return uint256(block.timestamp) - _entanglementTimestamp[particleId];
    }


    // --- Entanglement Actions ---

    /**
     * @dev Transfers Energy from the caller (who must own/delegate an entangled particle)
     *      to the owner of its entangled pair.
     * @param particleId Your entangled particle ID.
     * @param amount Amount of Energy to transfer.
     */
    function transferEnergyViaEntanglement(uint256 particleId, uint256 amount) external onlyParticleOwnerOrDelegate(particleId) whenEntanglementNotPaused {
        uint256 entangledId = _entangledPairs[particleId];
        if (entangledId == 0) revert EntangledEnergyTransferRequiresEntanglement();

        address senderOwner = _particleOwners[particleId];
        address recipientOwner = _particleOwners[entangledId];

        // Ensure the caller is authorized for the particle associated with the sender owner
        if (senderOwner != msg.sender && !_particleActionDelegates[particleId][msg.sender]) {
             revert NotOwnerOrDelegate(); // Should be caught by modifier, but double check
        }

        _transferEnergy(senderOwner, recipientOwner, amount);

        // Optional: Apply a small state change based on energy transfer
        _updateParticleState(particleId, uint8(uint256(_particleStates[particleId].stateValue) > amount ? uint256(_particleStates[particleId].stateValue) - uint256(amount) % 5 : 0), "Energy Transfer");
        _updateParticleState(entangledId, uint8(uint256(_particleStates[entangledId].stateValue) + uint256(amount) % 5), "Energy Reception");
    }

    /**
     * @dev Simulates the "collapse" of the states of an entangled pair based on their current values.
     *      Rules are simplified: e.g., similar states converge up, different states converge down.
     *      Can be triggered by the owner (or delegate) of either entangled particle.
     */
    function collapseEntangledStates(uint256 particleId) external onlyParticleOwnerOrDelegate(particleId) whenEntanglementNotPaused {
        uint256 entangledId = _entangledPairs[particleId];
        if (entangledId == 0) revert NotEntangled(particleId);

        ParticleState storage state1 = _particleStates[particleId];
        ParticleState storage state2 = _particleStates[entangledId];

        uint8 s1 = state1.stateValue;
        uint8 s2 = state2.stateValue;
        uint8 newState1;
        uint8 newState2;

        uint256 stabilityDuration = uint256(block.timestamp) - _entanglementTimestamp[particleId];
        uint256 stabilityBonus = stabilityDuration / 1 days * entanglementStabilityBonusFactor; // Bonus based on duration

        // Simple collapse rules based on state similarity
        if (s1 > s2) {
            if (s1 - s2 < 20) { // States are somewhat similar
                newState1 = uint8(s1 + stabilityBonus > 255 ? 255 : s1 + stabilityBonus);
                newState2 = uint8(s2 + stabilityBonus > 255 ? 255 : s2 + stabilityBonus);
            } else { // States are quite different
                 newState1 = uint8(s1 > 5 ? s1 - 5 : 0);
                 newState2 = uint8(s2 > 5 ? s2 - 5 : 0);
            }
        } else if (s2 > s1) {
             if (s2 - s1 < 20) { // States are somewhat similar
                newState1 = uint8(s1 + stabilityBonus > 255 ? 255 : s1 + stabilityBonus);
                newState2 = uint8(s2 + stabilityBonus > 255 ? 255 : s2 + stabilityBonus);
            } else { // States are quite different
                 newState1 = uint8(s1 > 5 ? s1 - 5 : 0);
                 newState2 = uint8(s2 > 5 ? s2 - 5 : 0);
            }
        } else { // States are identical
            newState1 = uint8(s1 + stabilityBonus > 255 ? 255 : s1 + stabilityBonus);
            newState2 = newState1;
        }

        _updateParticleState(particleId, newState1, "Entanglement Collapse");
        _updateParticleState(entangledId, newState2, "Entanglement Collapse");
    }

     /**
     * @dev Attempts to make the states of an entangled pair more correlated towards a target value.
     *      This is a probabilistic action. Success chance might depend on stability/states.
     *      Can be triggered by the owner (or delegate) of either entangled particle.
     */
    function induceStateCorrelation(uint256 particleId, uint8 targetValue) external onlyParticleOwnerOrDelegate(particleId) whenEntanglementNotPaused {
         uint256 entangledId = _entangledPairs[particleId];
         if (entangledId == 0) revert NotEntangled(particleId);

         ParticleState storage state1 = _particleStates[particleId];
         ParticleState storage state2 = _particleStates[entangledId];

         uint256 seed = _getPseudoRandomSeed();
         // Simplified success probability: higher if states are closer to target or more stable
         uint256 stabilityDuration = uint256(block.timestamp) - _entanglementTimestamp[particleId];
         uint256 proximity1 = uint256(state1.stateValue > targetValue ? state1.stateValue - targetValue : targetValue - state1.stateValue);
         uint256 proximity2 = uint256(state2.stateValue > targetValue ? state2.stateValue - targetValue : targetValue - state2.stateValue);

         // Simulate probability based on inverse proximity and stability (higher stability = better chance)
         // Max proximity 255. Stability bonus adds to 'chance' vs random modulo.
         uint256 successChanceBase = (510 - proximity1 - proximity2) / 5; // 0-100, closer to target is higher base
         uint256 successChance = successChanceBase + stabilityDuration / 1 hours; // Add bonus for stability

         if (seed % 100 < successChance) { // Simulate successful correlation
              uint8 correlatedState1 = uint8((uint256(state1.stateValue) + targetValue) / 2);
              uint8 correlatedState2 = uint8((uint256(state2.stateValue) + targetValue) / 2);

              _updateParticleState(particleId, correlatedState1, "State Correlation Induced");
              _updateParticleState(entangledId, correlatedState2, "State Correlation Induced");
         } else {
              // Optional: penalize with a slight state change for failed attempt
               _updateParticleState(particleId, uint8(state1.stateValue > 1 ? state1.stateValue - 1 : 0), "State Correlation Failed");
               _updateParticleState(entangledId, uint8(state2.stateValue > 1 ? state2.stateValue - 1 : 0), "State Correlation Failed");
         }
    }

     /**
     * @dev Breaks entanglement and transfers Energy from one owner to the other based on the state difference
     *      at the moment of disentanglement. Requires ownership/delegation of one particle.
     *      Simulates a "release" of energy proportional to the state difference.
     */
    function disentangleAndTransferEnergy(uint256 particleId) external onlyParticleOwnerOrDelegate(particleId) whenEntanglementNotPaused {
        uint256 entangledId = _entangledPairs[particleId];
        if (entangledId == 0) revert NotEntangled(particleId);

        address owner1 = _particleOwners[particleId];
        address owner2 = _particleOwners[entangledId];

        // Determine which owner initiated the disentanglement (this could affect rules)
        // For simplicity here, rule is based purely on state difference, initiator gets energy.
        address energyRecipient = msg.sender; // Assumes initiator gets energy flow if eligible
        address energySender;

        if (owner1 == msg.sender || _particleActionDelegates[particleId][msg.sender]) {
             energyRecipient = owner1;
             energySender = owner2;
        } else if (owner2 == msg.sender || _particleActionDelegates[entangledId][msg.sender]) {
             energyRecipient = owner2;
             energySender = owner1;
        } else {
             revert NotOwnerOrDelegate(); // Should be caught by modifier, but belt and suspenders
        }

        ParticleState storage state1 = _particleStates[particleId];
        ParticleState storage state2 = _particleStates[entangledId];

        uint256 stateDifference = uint256(state1.stateValue > state2.stateValue ? state1.stateValue - state2.stateValue : state2.stateValue - state1.stateValue);

        // Calculate energy transfer amount based on state difference and stability factor
        uint256 energyTransferAmount = stateDifference * entanglementStabilityBonusFactor; // Use stability factor for calculation

        if (energyTransferAmount > 0) {
             // Ensure sender has enough energy. If not, transfer what they have.
             uint256 actualTransferAmount = energyTransferAmount;
             if (_energyBalances[energySender] < actualTransferAmount) {
                 actualTransferAmount = _energyBalances[energySender];
             }
             if (actualTransferAmount > 0) {
                _transferEnergy(energySender, energyRecipient, actualTransferAmount);
             }
        }

        // Break entanglement AFTER calculating and potentially transferring energy
        _breakEntanglement(particleId); // This breaks for both
    }


    // --- Delegation ---

    /**
     * @dev Grants an address permission to perform specific actions (like state changes,
     *      entanglement actions) on a single particle ID.
     *      Only the owner of the particle can grant delegation.
     */
    function grantParticleActionDelegate(uint256 particleId, address delegatee) external {
        address owner_ = _particleOwners[particleId];
        if (owner_ == address(0)) revert ParticleDoesNotExist(particleId);
        if (msg.sender != owner_) revert NotParticleOwner(msg.sender, particleId);
        if (delegatee == address(0)) revert InvalidRecipient();

        _particleActionDelegates[particleId][delegatee] = true;
        emit ParticleActionDelegateGranted(particleId, owner_, delegatee);
    }

    /**
     * @dev Revokes delegation permission for a single particle ID.
     *      Can be revoked by the particle owner or the delegatee themselves.
     */
    function revokeParticleActionDelegate(uint256 particleId, address delegatee) external {
        address owner_ = _particleOwners[particleId];
        if (owner_ == address(0)) revert ParticleDoesNotExist(particleId);

        // Only owner or the delegatee can revoke
        if (msg.sender != owner_ && msg.sender != delegatee) revert NotOwnerOrDelegate();

        _particleActionDelegates[particleId][delegatee] = false;
        emit ParticleActionDelegateRevoked(particleId, owner_, delegatee);
    }

     /**
     * @dev Checks if an address is a delegated action taker for a particle.
     */
    function isParticleActionDelegate(uint256 particleId, address delegatee) external view returns (bool) {
         if (_particleOwners[particleId] == address(0)) return false; // Does not exist, cannot be delegate
         return _particleActionDelegates[particleId][delegatee];
    }


    // --- Admin & Utility ---

    /**
     * @dev Allows the owner to pause or unpause entanglement requests and actions.
     */
    function pauseEntanglement(bool paused) external onlyOwner {
        entanglementPaused = paused;
    }

    /**
     * @dev Allows the owner to set the factor used in entanglement-related calculations.
     */
    function setEntanglementStabilityBonusFactor(uint256 factor) external onlyOwner {
        entanglementStabilityBonusFactor = factor;
    }

    // --- Additional Functions (to meet 20+ easily and add more features) ---

    // 1. Get total number of particles
    function totalParticles() external view returns (uint256) {
        return _nextTokenId; // _nextTokenId is the count of particles created
    }

    // 2. Mint initial Energy (admin only)
    function initialEnergyMint(address recipient, uint256 amount) external onlyOwner {
         _mintEnergy(recipient, amount);
    }

    // 3. Burn Energy (admin only - for cleanup or specific mechanics)
    function adminBurnEnergy(address account, uint256 amount) external onlyOwner {
        _burnEnergy(account, amount);
    }

    // 4. Transfer ownership of the contract (standard pattern)
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidRecipient();
        owner = newOwner;
    }

     // 5. Get last state change timestamp
     function getLastStateChangeTimestamp(uint256 particleId) external view returns (uint64) {
         if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
         return _particleStates[particleId].lastStateChangeTimestamp;
     }

     // 6. Force apply state change (Admin only, for corrections or special events)
     function adminForceStateChange(uint256 particleId, uint8 newStateValue) external onlyOwner {
         if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
         _updateParticleState(particleId, newStateValue, "Admin Override");
     }

     // 7. Admin create particle with specific initial state (Admin only)
     function adminCreateParticleWithState(address initialOwner, uint8 initialStateValue, bool decayResistance) external onlyOwner returns (uint256) {
         uint256 newParticleId = _nextTokenId++;
         _particleOwners[newParticleId] = initialOwner;
         _particleCount[initialOwner]++;

         _particleStates[newParticleId] = ParticleState({
             stateValue: initialStateValue,
             creationTimestamp: uint64(block.timestamp),
             lastStateChangeTimestamp: uint64(block.timestamp),
             decayResistance: decayResistance
         });

         emit ParticleCreated(initialOwner, newParticleId);
         emit ParticleStateChanged(newParticleId, 0, initialStateValue, "Admin Creation");
         return newParticleId;
     }

     // 8. Get entanglement request target
     function getEntanglementRequestTarget(uint256 requesterParticleId) external view returns (uint256) {
          return _entanglementRequests[requesterParticleId];
     }

     // 9. Cancel an entanglement request (by requester or target owner/delegate)
     function cancelEntanglementRequest(uint256 particleId1, uint256 particleId2) external {
          // Check if request exists from 1 to 2
          if (_entanglementRequests[particleId1] != particleId2) revert EntanglementRequestNotFound(particleId1, particleId2);

          // Must be owner/delegate of particle1 OR owner/delegate of particle2
          bool isOwnerOrDelegate1 = (_particleOwners[particleId1] == msg.sender || _particleActionDelegates[particleId1][msg.sender]);
          bool isOwnerOrDelegate2 = (_particleOwners[particleId2] == msg.sender || _particleActionDelegates[particleId2][msg.sender]);

          if (!isOwnerOrDelegate1 && !isOwnerOrDelegate2) {
               revert NotOwnerOrDelegate(); // Neither party authorized to cancel
          }

          delete _entanglementRequests[particleId1];
     }

     // 10. Get decay resistance status
     function getDecayResistance(uint256 particleId) external view returns (bool) {
         if (_particleOwners[particleId] == address(0)) revert ParticleDoesNotExist(particleId);
         return _particleStates[particleId].decayResistance;
     }

    // Total Functions: 37 + 10 = 47 (Including constructor)

}
```