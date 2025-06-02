Okay, let's design a smart contract that simulates a "Quantum Swarm" – a collection of unique, interacting entities (Quanta) whose properties exist in a probabilistic state until "measured" or interacting, and which can become "entangled".

This concept allows for:
1.  **Non-Fungible State:** Each Quanta is unique, but its state isn't static.
2.  **Probabilistic Properties:** State variables (`entropyFactors`) have a degree of uncertainty (`purity`).
3.  **Interaction Mechanics:** Interactions change states probabilistically and create "entanglement".
4.  **Entanglement:** Links between Quanta where measuring one affects the probable state of the other.
5.  **Measurement:** Forcing a probabilistic state to become more certain.
6.  **Emergent Behavior:** The swarm's overall state evolves based on individual interactions.

This is complex and gas-intensive for a real blockchain, especially the entanglement management and probabilistic state updates. This implementation will be a simplified model to illustrate the concepts and meet the function count requirement. *Crucially, on-chain randomness is hard and vulnerable; the pseudo-randomness here is for illustration only. A real application would need Chainlink VRF or similar.*

---

## QuantumSwarm Smart Contract Outline & Function Summary

**Concept:** A simulated ecosystem of unique, probabilistic entities ("Quanta") that interact, become entangled, and evolve based on probabilistic rules influenced by their internal state and interactions.

**Core Components:**

*   **Quanta:** A struct representing a single entity with properties like owner, existence status, purity (certainty of state), energy level, entropy factors (probabilistic properties), and a list of entangled Quanta IDs.
*   **State Management:** Mappings and variables to track Quanta, owners, and global state (like total Quanta).
*   **Interaction Logic:** Functions governing how Quanta interact, consuming energy, changing states probabilistically, creating/decaying entanglement, and potentially minting new Quanta.
*   **Measurement Logic:** Functions to "collapse" a Quanta's probabilistic state into a more certain one.
*   **Entanglement Management:** Functions to track, add, remove, and decay entanglement links.
*   **Resource Management:** Energy levels for Quanta, fees for operations.
*   **Configuration:** Owner-controlled parameters to tune the simulation dynamics.
*   **Ownership & Access Control:** Standard ownership patterns and pause functionality.

**Function Summary (29 Functions):**

*   **Lifecycle & Ownership (7):**
    1.  `constructor`: Initializes the contract owner and pause state.
    2.  `createGenesisQuanta`: Owner-only function to mint initial Quanta to seed the swarm.
    3.  `mintQuanta`: Allows users to mint new Quanta (at high uncertainty) by paying a fee.
    4.  `transferQuanta`: Allows a Quanta owner to transfer it to another address.
    5.  `burnQuanta`: Allows a Quanta owner to destroy it.
    6.  `transferOwnership`: Transfers contract ownership (owner only).
    7.  `renounceOwnership`: Renounces contract ownership (owner only).
*   **Core Interaction & State Change (7):**
    8.  `interactQuanta`: The primary function for two Quanta to interact, consuming energy/fees, changing state, and managing entanglement probabilistically.
    9.  `measureQuanta`: Forces a Quanta's probabilistic state (`purity`) to collapse towards certainty.
    10. `rechargeQuanta`: Increases a Quanta's energy level by paying a fee.
    11. `dissipateEntanglement`: Allows a user to attempt to break specific entanglement links of their Quanta.
    12. `triggerEntanglementDecay`: Allows anyone to trigger the decay process for a specific Quanta's entanglement links based on block height.
    13. `pauseInteractions`: Pauses core interaction functions (owner only).
    14. `unpauseInteractions`: Unpauses core interaction functions (owner only).
*   **Querying & Viewing State (7):**
    15. `getQuanta`: Retrieves the full state data for a specific Quanta.
    16. `getQuantaOwner`: Retrieves the owner address of a specific Quanta.
    17. `getEntangledQuantaIds`: Retrieves the list of Quanta IDs entangled with a specific Quanta.
    18. `getTotalExistingQuanta`: Returns the total number of non-burned Quanta.
    19. `getQuantaByOwner`: Retrieves a list of Quanta IDs owned by a specific address.
    20. `checkEntanglementStatus`: Checks if two specific Quanta are currently entangled.
    21. `observeQuanta`: Provides a view of a Quanta's current state, including probabilistic aspects (represented by purity).
*   **Configuration & Admin (8):**
    22. `setInteractionFee`: Sets the fee required to call `interactQuanta` (owner only).
    23. `setEnergyCost`: Sets the energy consumed by a Quanta during `interactQuanta` (owner only).
    24. `setPurityCollapseFactor`: Sets how much `purity` increases during interaction/measurement (owner only).
    25. `setEntropyTransferFactor`: Sets how much `entropyFactors` are influenced by interaction partners (owner only).
    26. `setEntanglementDecayBlocks`: Sets the number of blocks after which entanglement links *can* be decayed (owner only).
    27. `setNewQuantaProbability`: Sets the probability (scaled 0-10000) of a new Quanta being minted during interaction (owner only).
    28. `setRechargeAmount`: Sets the amount of energy gained via `rechargeQuanta` (owner only).
    29. `withdrawFees`: Allows the owner to withdraw collected ETH fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumSwarm
 * @dev A smart contract simulating a swarm of unique, probabilistic entities (Quanta)
 *      that interact, become entangled, and evolve based on defined rules.
 *      This contract demonstrates advanced concepts like managing probabilistic state,
 *      simulating interactions with probabilistic outcomes, and handling dynamic relationships (entanglement).
 *      NOTE: On-chain randomness is inherently insecure. The pseudo-randomness here
 *      is for illustrative purposes only. A production system requires a secure VRF (e.g., Chainlink VRF).
 */
contract QuantumSwarm {

    // --- Outline & Function Summary Above ---

    // --- Data Structures ---

    /**
     * @dev Represents a single Quantum entity.
     *      'purity' (uint16): 0 = fully superposition (uncertain), 65535 = fully collapsed (certain).
     *      'energyLevel' (uint32): Resource for interactions.
     *      'entropyFactors' (uint16[3]): Probabilistic properties (e.g., color, spin, flavor). The stored value
     *                                   is the *dominant* value, but 'purity' indicates the certainty of this dominance.
     *      'entangledQuanta' (uint256[]): IDs of other Quanta this one is entangled with.
     *      'creationBlock' (uint256): Block number when created.
     *      'lastInteractionBlock' (uint256): Block number of the last interaction involving this Quanta.
     *      'exists' (bool): True if the Quanta is active and not burned.
     */
    struct Quanta {
        address owner;
        bool exists;
        uint256 creationBlock;
        uint256 lastInteractionBlock;
        uint16 purity; // 0-65535
        uint32 energyLevel;
        uint16[3] entropyFactors; // Example properties
        uint256[] entangledQuanta; // Array of entangled Quanta IDs
    }

    // --- State Variables ---

    mapping(uint256 => Quanta) private _quanta;
    uint256 private _nextQuantaId;
    uint256 private _totalExistingQuanta;
    // Mapping for faster lookup of Quanta owned by an address (can be gas intensive for updates with large number of quanta per owner)
    mapping(address => uint256[] shallow) private _ownerToQuantaIds;

    address public owner;
    bool private _paused;

    // Simulation Parameters (Tunable by owner)
    uint256 public interactionFee = 0.01 ether; // Fee to interact
    uint32 public energyCostPerInteraction = 100; // Energy cost for one Quanta
    uint16 public purityCollapseFactor = 1000; // Amount purity increases on interaction/measurement
    uint16 public entropyTransferFactor = 5000; // Influence factor for entropy transfer (scaled 0-10000)
    uint256 public entanglementDecayBlocks = 100; // Blocks after which entanglement *can* be decayed
    uint16 public newQuantaProbability = 500; // Probability (scaled 0-10000) of new Quanta creation on interaction
    uint32 public rechargeAmount = 500; // Energy gained when recharging

    // --- Events ---

    event QuantaCreated(uint256 indexed quantaId, address indexed owner, uint256 creationBlock);
    event QuantaTransferred(uint256 indexed quantaId, address indexed from, address indexed to);
    event QuantaBurned(uint256 indexed quantaId, address indexed owner);
    event QuantaInteracted(uint256 indexed quantaId1, uint256 indexed quantaId2, uint256 interactionBlock);
    event QuantaMeasured(uint256 indexed quantaId, uint256 interactionBlock);
    event QuantaRecharged(uint256 indexed quantaId, uint32 newEnergyLevel);
    event EntanglementAdded(uint256 indexed quantaId1, uint256 indexed quantaId2);
    event EntanglementRemoved(uint256 indexed quantaId1, uint256 indexed quantaId2);
    event ParametersUpdated(string paramName, uint256 newValue);
    event Paused(address account);
    event Unpaused(address account);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _nextQuantaId = 1; // Start IDs from 1
        _paused = false;
        emit OwnershipTransferred(address(0), owner);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Pseudo-random number generator based on multiple inputs.
     *      WARNING: This is NOT cryptographically secure and should not be used
     *      for applications requiring genuine, unpredictable randomness.
     *      Miner manipulation is possible. Use Chainlink VRF or similar for security.
     */
    function _getRandomUint(uint256 seed, uint256 range) internal view returns (uint256) {
        if (range == 0) return 0;
        // Combine transaction details and block data for a basic seed
        uint256 combinedSeed = seed ^ uint256(keccak256(abi.encodePacked(
            msg.sender,
            tx.origin,
            block.timestamp,
            block.number,
            blockhash(block.number - 1 < block.number ? block.number - 1 : 0), // Use previous blockhash
            block.basefee // Add basefee (post EIP-1559)
        )));
        return uint256(keccak256(abi.encodePacked(combinedSeed))) % range;
    }

    /**
     * @dev Adds a Quanta ID to an owner's list.
     * @param owner The owner's address.
     * @param quantaId The ID of the Quanta to add.
     */
    function _addQuantaToOwnerList(address owner, uint256 quantaId) internal {
        _ownerToQuantaIds[owner].push(quantaId);
    }

    /**
     * @dev Removes a Quanta ID from an owner's list.
     *      Finds the ID and swaps it with the last element before popping.
     * @param owner The owner's address.
     * @param quantaId The ID of the Quanta to remove.
     */
    function _removeQuantaFromOwnerList(address owner, uint256 quantaId) internal {
        uint256[] storage ownerQuanta = _ownerToQuantaIds[owner];
        for (uint256 i = 0; i < ownerQuanta.length; i++) {
            if (ownerQuanta[i] == quantaId) {
                ownerQuanta[i] = ownerQuanta[ownerQuanta.length - 1];
                ownerQuanta.pop();
                break; // ID found and removed
            }
        }
        // Note: If an owner's list gets extremely long and removals are frequent,
        // this linear scan can become a gas bottleneck.
    }

    /**
     * @dev Adds an entanglement link between two Quanta.
     *      Ensures the link is added symmetrically and is not a self-link or duplicate.
     */
    function _addEntanglement(uint256 id1, uint256 id2) internal {
        if (id1 == id2) return; // Cannot entangle with self

        Quanta storage q1 = _quanta[id1];
        Quanta storage q2 = _quanta[id2];

        require(q1.exists, "Quanta 1 does not exist");
        require(q2.exists, "Quanta 2 does not exist");

        // Check if already entangled (simplified check, could optimize)
        bool alreadyEntangled = false;
        for (uint256 i = 0; i < q1.entangledQuanta.length; i++) {
            if (q1.entangledQuanta[i] == id2) {
                alreadyEntangled = true;
                break;
            }
        }

        if (!alreadyEntangled) {
            q1.entangledQuanta.push(id2);
            q2.entangledQuanta.push(id1);
            emit EntanglementAdded(id1, id2);
        }
    }

    /**
     * @dev Removes an entanglement link between two Quanta.
     *      Removes the link symmetrically.
     */
    function _removeEntanglement(uint256 id1, uint256 id2) internal {
         Quanta storage q1 = _quanta[id1];
         Quanta storage q2 = _quanta[id2];

         if (!q1.exists || !q2.exists) return; // Cannot remove entanglement for non-existent quanta

         // Remove id2 from q1's list
         uint256[] storage q1Entangled = q1.entangledQuanta;
         for (uint256 i = 0; i < q1Entangled.length; i++) {
             if (q1Entangled[i] == id2) {
                 q1Entangled[i] = q1Entangled[q1Entangled.length - 1];
                 q1Entangled.pop();
                 break; // Found and removed
             }
         }

         // Remove id1 from q2's list
         uint256[] storage q2Entangled = q2.entangledQuanta;
         for (uint256 i = 0; i < q2Entangled.length; i++) {
             if (q2Entangled[i] == id1) {
                 q2Entangled[i] = q2Entangled[q2Entangled.length - 1];
                 q2Entangled.pop();
                 break; // Found and removed
             }
         }

         emit EntanglementRemoved(id1, id2);
    }

    /**
     * @dev Applies probabilistic outcome based on current state and a seed.
     *      Illustrative logic: Blends existing entropy factors with potential
     *      new factors based on purity and a random seed.
     */
    function _applyProbabilisticOutcome(Quanta storage q, uint256 seed) internal {
        if (q.purity == 65535) return; // Fully collapsed, no probabilistic change

        // Calculate a target state based on the seed (highly simplified)
        uint16[3] memory targetFactors;
        for (uint i = 0; i < 3; i++) {
             // Use a distinct seed for each factor
            targetFactors[i] = uint16(_getRandomUint(seed + i, 65536));
        }

        // Blend current factors with target factors based on uncertainty (1 - purity/65535)
        // More uncertain (lower purity) means more influence from the target state.
        // This blending logic is complex and gas-intensive. Simplified approach below.
        // Let's simplify: if purity is low, there's a chance to jump towards the target.
        // If purity is high, small changes or no change.

        uint256 uncertainty = 65535 - q.purity; // 0 (high purity) to 65535 (low purity)

        uint256 randomValue = _getRandomUint(seed + 100, 65536);

        if (randomValue < uncertainty) {
             // Apply a change proportional to uncertainty and transfer factor (if applicable)
            for (uint i = 0; i < 3; i++) {
                // Simplified blending: new factor is weighted average or a jump
                 uint256 blendAmount = (uncertainty * entropyTransferFactor) / 10000; // Use transfer factor for influence amount
                 uint256 blendedFactor = (uint256(q.entropyFactors[i]) * (65536 - blendAmount) + uint256(targetFactors[i]) * blendAmount) / 65536;
                 q.entropyFactors[i] = uint16(blendedFactor);
            }
        }

        // Increase purity towards collapse
        q.purity = uint16(Math.min(q.purity + purityCollapseFactor, 65535));
    }

     /**
     * @dev Decays entanglement links for a specific Quanta if block height conditions are met.
     *      Removes links that were added before (current block - decay blocks).
     *      NOTE: This does NOT track when *each specific link* was added, only the Quanta's
     *      last interaction block. A more precise implementation would track link age.
     *      This simple version checks against the Quanta's last interaction or creation block.
     */
    function _decayEntanglement(Quanta storage q) internal {
        if (q.entangledQuanta.length == 0) return;

        uint256 currentBlock = block.number;
        uint256 effectiveLastActivity = q.lastInteractionBlock > 0 ? q.lastInteractionBlock : q.creationBlock;

        if (currentBlock < effectiveLastActivity + entanglementDecayBlocks) {
            return; // Not enough blocks passed since last significant activity
        }

        // Create a new array for links to keep
        uint224[] memory linksToKeep = new uint224[](q.entangledQuanta.length); // Use uint224 to save gas
        uint256 keepCount = 0;

        // Iterate through current links and decide which to keep (simplified: keep 50% probabilistically after decay window)
        uint256 seed = uint256(keccak256(abi.encodePacked(q.entangledQuanta, currentBlock)));

        for (uint256 i = 0; i < q.entangledQuanta.length; i++) {
             uint256 entangledId = q.entangledQuanta[i];
             if (entangledId == 0 || !_quanta[entangledId].exists) {
                 // Remove if the entangled Quanta no longer exists
                 _removeEntanglement(q.entangledData[i].targetId, q.id); // Need symmetric removal logic
                 continue;
             }

             // Probabilistic decay: 50% chance to decay links after the window
             // (again, simplified, could use more complex decay rules based on purity/energy)
             if (_getRandomUint(seed + entangledId, 100) < 50) { // 50% chance to decay
                  _removeEntanglement(q.id, entangledId); // Remove this specific link symmetrically
             } else {
                  linksToKeep[keepCount] = uint224(entangledId); // Cast needed
                  keepCount++;
             }
        }

        // Rebuild the entangledQuanta array (efficiently)
        delete q.entangledQuanta; // Clear storage array
        for(uint i = 0; i < keepCount; i++){
            q.entangledQuanta.push(linksToKeep[i]);
        }
    }

    // --- Lifecycle & Ownership Functions ---

    /**
     * @dev Initializes the contract owner.
     */
    // constructor already serves this purpose

    /**
     * @dev Owner-only function to create initial Genesis Quanta.
     * @param initialOwners Addresses to receive Genesis Quanta.
     * @param count Number of Genesis Quanta per owner.
     */
    function createGenesisQuanta(address[] calldata initialOwners, uint256 count) external onlyOwner {
        require(_totalExistingQuanta == 0, "Genesis Quanta already created"); // Prevent multiple genesis events

        for (uint i = 0; i < initialOwners.length; i++) {
            require(initialOwners[i] != address(0), "Invalid owner address");
            for (uint j = 0; j < count; j++) {
                 uint256 newId = _nextQuantaId++;
                _quanta[newId] = Quanta({
                    owner: initialOwners[i],
                    exists: true,
                    creationBlock: block.number,
                    lastInteractionBlock: 0,
                    purity: 1000, // Start with low purity (high uncertainty)
                    energyLevel: 1000, // Initial energy
                    entropyFactors: [uint16(j), uint16(i), uint16(newId % 256)], // Initial random-ish factors
                    entangledQuanta: new uint256[](0) // Start not entangled
                });
                _totalExistingQuanta++;
                _addQuantaToOwnerList(initialOwners[i], newId);
                emit QuantaCreated(newId, initialOwners[i], block.number);
            }
        }
    }

    /**
     * @dev Allows anyone to mint a new Quanta by paying the interaction fee.
     *      New Quanta start with low purity (high uncertainty).
     */
    function mintQuanta() public payable whenNotPaused {
        require(msg.value >= interactionFee, "Insufficient fee to mint");

        uint256 newId = _nextQuantaId++;
        _quanta[newId] = Quanta({
            owner: msg.sender,
            exists: true,
            creationBlock: block.number,
            lastInteractionBlock: 0,
            purity: 500, // Start with very low purity
            energyLevel: rechargeAmount, // Initial energy = recharge amount
            entropyFactors: [uint16(_getRandomUint(newId, 65536)), uint16(_getRandomUint(newId + 1, 65536)), uint16(_getRandomUint(newId + 2, 65536))], // Highly random initial factors
            entangledQuanta: new uint256[](0)
        });
        _totalExistingQuanta++;
        _addQuantaToOwnerList(msg.sender, newId);
        emit QuantaCreated(newId, msg.sender, block.number);

        // Refund excess ETH
        if (msg.value > interactionFee) {
            payable(msg.sender).transfer(msg.value - interactionFee);
        }
    }

    /**
     * @dev Transfers ownership of a Quanta.
     * @param quantaId The ID of the Quanta to transfer.
     * @param to The address to transfer to.
     */
    function transferQuanta(uint256 quantaId, address to) public whenNotPaused {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");
        require(quanta.owner == msg.sender, "Must own the Quanta to transfer");
        require(to != address(0), "Cannot transfer to zero address");

        address oldOwner = quanta.owner;
        _removeQuantaFromOwnerList(oldOwner, quantaId);
        quanta.owner = to;
        _addQuantaToOwnerList(to, quantaId);
        emit QuantaTransferred(quantaId, oldOwner, to);
    }

    /**
     * @dev Destroys a Quanta.
     * @param quantaId The ID of the Quanta to burn.
     */
    function burnQuanta(uint256 quantaId) public whenNotPaused {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");
        require(quanta.owner == msg.sender, "Must own the Quanta to burn");

        address burner = msg.sender;

        // Clean up owner list
        _removeQuantaFromOwnerList(burner, quantaId);

        // Remove entanglement links symmetrically (potentially gas intensive if highly entangled)
        uint256[] memory entangled = quanta.entangledQuanta; // Read into memory before deleting storage array
         for (uint i = 0; i < entangled.length; i++) {
            if (_quanta[entangled[i]].exists) { // Only remove link if the other side still exists
                _removeEntanglement(entangled[i], quantaId);
            }
         }

        // Mark as non-existent and clear sensitive data
        quanta.exists = false;
        quanta.owner = address(0);
        delete quanta.entangledQuanta; // Clear storage array

        _totalExistingQuanta--;
        emit QuantaBurned(quantaId, burner);
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Renounces ownership of the contract.
     *      Can only be called by the current owner.
     */
    function renounceOwnership() public onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    // --- Core Interaction & State Change Functions ---

    /**
     * @dev Initiates an interaction between two Quanta.
     *      Consumes energy, requires fees, changes state probabilistically,
     *      and manages entanglement and potential new Quanta creation.
     * @param quantaId1 The ID of the first Quanta.
     * @param quantaId2 The ID of the second Quanta.
     */
    function interactQuanta(uint256 quantaId1, uint256 quantaId2) public payable whenNotPaused {
        require(quantaId1 != quantaId2, "Cannot interact a Quanta with itself");
        Quanta storage q1 = _quanta[quantaId1];
        Quanta storage q2 = _quanta[quantaId2];

        require(q1.exists, "Quanta 1 does not exist");
        require(q2.exists, "Quanta 2 does not exist");
        require(q1.owner == msg.sender || q2.owner == msg.sender, "Must own at least one Quanta to interact");
        require(q1.energyLevel >= energyCostPerInteraction, "Quanta 1 insufficient energy");
        require(q2.energyLevel >= energyCostPerInteraction, "Quanta 2 insufficient energy");
        require(msg.value >= interactionFee, "Insufficient fee for interaction");

        // Consume resources
        q1.energyLevel -= energyCostPerInteraction;
        q2.energyLevel -= energyCostPerInteraction;
        // Fee is collected by the contract

        // Apply probabilistic state changes based on interaction
        uint256 interactionSeed = uint256(keccak256(abi.encodePacked(quantaId1, quantaId2, block.timestamp, block.number)));
        _applyProbabilisticOutcome(q1, interactionSeed); // Apply outcome to q1
        _applyProbabilisticOutcome(q2, interactionSeed + 1); // Apply outcome to q2 with a different seed part

        // Manage Entanglement
        _addEntanglement(quantaId1, quantaId2); // Interaction increases entanglement chance
        // Probabilistically decay existing entanglement for both participants
        _decayEntanglement(q1);
        _decayEntanglement(q2);

        // Probabilistically create a new entangled Quanta
        uint256 createSeed = uint256(keccak256(abi.encodePacked(quantaId1, quantaId2, block.timestamp, block.number, q1.purity, q2.purity)));
        if (_getRandomUint(createSeed, 10000) < newQuantaProbability) {
            uint256 newId = _nextQuantaId++;
            address newOwner = msg.sender; // New Quanta goes to the initiator
            _quanta[newId] = Quanta({
                owner: newOwner,
                exists: true,
                creationBlock: block.number,
                lastInteractionBlock: block.number,
                purity: 100, // Very low purity
                energyLevel: rechargeAmount / 2, // Less initial energy
                entropyFactors: [
                    uint16((uint256(q1.entropyFactors[0]) + uint256(q2.entropyFactors[0])) / 2 + uint256(_getRandomUint(createSeed + 10, 100)) - 50), // Blend + random
                    uint16((uint256(q1.entropyFactors[1]) + uint256(q2.entropyFactors[1])) / 2 + uint256(_getRandomUint(createSeed + 11, 100)) - 50),
                    uint16((uint256(q1.entropyFactors[2]) + uint256(q2.entropyFactors[2])) / 2 + uint256(_getRandomUint(createSeed + 12, 100)) - 50)
                ],
                entangledQuanta: new uint256[](0) // Initialize empty, entanglement added below
            });
            _totalExistingQuanta++;
            _addQuantaToOwnerList(newOwner, newId);
            emit QuantaCreated(newId, newOwner, block.number);

            // New Quanta is entangled with the interacting pair
            _addEntanglement(newId, quantaId1);
            _addEntanglement(newId, quantaId2);
        }


        q1.lastInteractionBlock = block.number;
        q2.lastInteractionBlock = block.number;

        emit QuantaInteracted(quantaId1, quantaId2, block.number);

         // Refund excess ETH
        if (msg.value > interactionFee) {
            payable(msg.sender).transfer(msg.value - interactionFee);
        }
    }

    /**
     * @dev Forces a "measurement" on a Quanta, collapsing its purity towards maximum.
     *      Deterministic outcome based on current state and a seed.
     * @param quantaId The ID of the Quanta to measure.
     */
    function measureQuanta(uint256 quantaId) public payable whenNotPaused {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");
        require(quanta.owner == msg.sender, "Must own the Quanta to measure");
        require(quanta.energyLevel >= energyCostPerInteraction / 2, "Insufficient energy to measure"); // Measurement costs less energy
        require(msg.value >= interactionFee / 2, "Insufficient fee to measure"); // Measurement costs less fee

        quanta.energyLevel -= energyCostPerInteraction / 2;

        // Force purity to maximum (full collapse)
        quanta.purity = 65535;

        // The entropy factors become fixed representations of the measured state.
        // (In this model, they are already stored as dominant values, measurement just makes them certain).

        quanta.lastInteractionBlock = block.number;

        emit QuantaMeasured(quantaId, block.number);

         // Refund excess ETH
        uint256 measurementFee = interactionFee / 2;
        if (msg.value > measurementFee) {
            payable(msg.sender).transfer(msg.value - measurementFee);
        }
    }

     /**
     * @dev Increases a Quanta's energy level.
     * @param quantaId The ID of the Quanta to recharge.
     */
    function rechargeQuanta(uint256 quantaId) public payable whenNotPaused {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");
        require(quanta.owner == msg.sender, "Must own the Quanta to recharge");
        require(msg.value >= interactionFee / 4, "Insufficient fee to recharge"); // Recharge costs a small fee

        // Add energy up to a cap (e.g., twice recharge amount)
        uint32 energyCap = rechargeAmount * 2;
        quanta.energyLevel = uint32(Math.min(uint256(quanta.energyLevel) + rechargeAmount, uint256(energyCap)));

        emit QuantaRecharged(quantaId, quanta.energyLevel);

         // Refund excess ETH
        uint256 rechargeFee = interactionFee / 4;
        if (msg.value > rechargeFee) {
            payable(msg.sender).transfer(msg.value - rechargeFee);
        }
    }

    /**
     * @dev Allows a Quanta owner to attempt to break specific entanglement links.
     *      Success is probabilistic.
     * @param quantaId The ID of the Quanta.
     * @param targetQuantaId The ID of the entangled Quanta to attempt to unlink from.
     */
    function dissipateEntanglement(uint256 quantaId, uint256 targetQuantaId) public whenNotPaused {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");
        require(quanta.owner == msg.sender, "Must own the Quanta to dissipate entanglement");
        require(quantaId != targetQuantaId, "Cannot dissipate entanglement with self");

        // Check if they are actually entangled
        bool isEntangled = false;
        for (uint i = 0; i < quanta.entangledQuanta.length; i++) {
            if (quanta.entangledQuanta[i] == targetQuantaId) {
                isEntangled = true;
                break;
            }
        }
        require(isEntangled, "Quanta are not entangled");

        // Probabilistic success based on energy/purity/randomness (simplified: 70% chance)
        uint256 dissipationSeed = uint256(keccak256(abi.encodePacked(quantaId, targetQuantaId, block.timestamp, block.number)));
        if (_getRandomUint(dissipationSeed, 100) < 70) { // 70% success chance
            _removeEntanglement(quantaId, targetQuantaId);
        } else {
            // Optional: slight purity increase or energy cost on failure
             quanta.purity = uint16(Math.min(quanta.purity + purityCollapseFactor/10, 65535));
        }
    }

    /**
     * @dev Allows anyone to trigger entanglement decay for a specific Quanta.
     *      Checks if enough blocks have passed since the Quanta's last activity.
     *      This helps manage array size and gas costs by allowing others to pay for decay.
     * @param quantaId The ID of the Quanta to decay entanglement for.
     */
    function triggerEntanglementDecay(uint256 quantaId) public whenNotPaused {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");

        _decayEntanglement(quanta); // Call the internal decay logic
    }


    /**
     * @dev Pauses all core interaction and state change functions.
     *      Only callable by the owner.
     */
    function pauseInteractions() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses core interaction and state change functions.
     *      Only callable by the owner.
     */
    function unpauseInteractions() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Querying & Viewing State Functions ---

    /**
     * @dev Retrieves the full state data for a specific Quanta.
     * @param quantaId The ID of the Quanta.
     * @return The Quanta struct data.
     */
    function getQuanta(uint256 quantaId) public view returns (Quanta memory) {
        require(_quanta[quantaId].exists, "Quanta does not exist");
        return _quanta[quantaId];
    }

     /**
     * @dev Retrieves the owner address of a specific Quanta.
     * @param quantaId The ID of the Quanta.
     * @return The owner address.
     */
    function getQuantaOwner(uint256 quantaId) public view returns (address) {
        require(_quanta[quantaId].exists, "Quanta does not exist");
        return _quanta[quantaId].owner;
    }

    /**
     * @dev Retrieves the list of Quanta IDs entangled with a specific Quanta.
     * @param quantaId The ID of the Quanta.
     * @return An array of entangled Quanta IDs.
     */
    function getEntangledQuantaIds(uint256 quantaId) public view returns (uint256[] memory) {
        require(_quanta[quantaId].exists, "Quanta does not exist");
        return _quanta[quantaId].entangledQuanta;
    }

    /**
     * @dev Returns the total number of existing (non-burned) Quanta in the swarm.
     * @return The total count of Quanta.
     */
    function getTotalExistingQuanta() public view returns (uint256) {
        return _totalExistingQuanta;
    }

    /**
     * @dev Retrieves a list of all Quanta IDs owned by a specific address.
     *      NOTE: This relies on a cached list. If an owner has thousands of Quanta,
     *      this could exceed block gas limits when reading.
     * @param targetOwner The address to query.
     * @return An array of Quanta IDs owned by the address.
     */
    function getQuantaByOwner(address targetOwner) public view returns (uint256[] memory) {
        return _ownerToQuantaIds[targetOwner];
    }

    /**
     * @dev Checks if two specific Quanta are currently entangled.
     * @param quantaId1 The ID of the first Quanta.
     * @param quantaId2 The ID of the second Quanta.
     * @return True if they are entangled, false otherwise.
     */
    function checkEntanglementStatus(uint256 quantaId1, uint256 quantaId2) public view returns (bool) {
        if (quantaId1 == quantaId2) return false;
        Quanta storage q1 = _quanta[quantaId1];
        if (!q1.exists) return false;

        for (uint i = 0; i < q1.entangledQuanta.length; i++) {
            if (q1.entangledQuanta[i] == quantaId2) {
                return true;
            }
        }
        return false;
    }

     /**
     * @dev Provides a view of a Quanta's current state.
     *      Includes purity and entropy factors, reflecting the probabilistic nature.
     * @param quantaId The ID of the Quanta to observe.
     * @return owner, exists, purity, energyLevel, entropyFactors.
     */
    function observeQuanta(uint256 quantaId) public view returns (address, bool, uint16, uint32, uint16[3] memory) {
        Quanta storage quanta = _quanta[quantaId];
        require(quanta.exists, "Quanta does not exist");
        return (quanta.owner, quanta.exists, quanta.purity, quanta.energyLevel, quanta.entropyFactors);
    }


    // --- Configuration & Admin Functions ---

    /**
     * @dev Sets the fee required to call `interactQuanta` and `mintQuanta`.
     * @param fee The new fee amount in wei.
     */
    function setInteractionFee(uint256 fee) public onlyOwner {
        interactionFee = fee;
        emit ParametersUpdated("interactionFee", fee);
    }

    /**
     * @dev Sets the energy consumed by a Quanta during `interactQuanta`.
     * @param cost The new energy cost.
     */
    function setEnergyCost(uint32 cost) public onlyOwner {
        energyCostPerInteraction = cost;
        emit ParametersUpdated("energyCostPerInteraction", cost);
    }

     /**
     * @dev Sets the amount purity increases during interaction/measurement.
     * @param factor The new purity collapse factor (0-65535).
     */
    function setPurityCollapseFactor(uint16 factor) public onlyOwner {
        purityCollapseFactor = factor;
        emit ParametersUpdated("purityCollapseFactor", factor);
    }

     /**
     * @dev Sets the influence factor for entropy transfer during interaction.
     * @param factor The new entropy transfer factor (scaled 0-10000).
     */
    function setEntropyTransferFactor(uint16 factor) public onlyOwner {
        entropyTransferFactor = factor;
        emit ParametersUpdated("entropyTransferFactor", factor);
    }


    /**
     * @dev Sets the number of blocks after which entanglement links *can* be decayed.
     * @param blocks The minimum number of blocks.
     */
    function setEntanglementDecayBlocks(uint256 blocks) public onlyOwner {
        entanglementDecayBlocks = blocks;
         emit ParametersUpdated("entanglementDecayBlocks", blocks);
    }

    /**
     * @dev Sets the probability (scaled 0-10000) of a new Quanta being minted during interaction.
     * @param probability The new probability (e.g., 500 for 5%).
     */
    function setNewQuantaProbability(uint16 probability) public onlyOwner {
        require(probability <= 10000, "Probability must be <= 10000");
        newQuantaProbability = probability;
        emit ParametersUpdated("newQuantaProbability", probability);
    }

     /**
     * @dev Sets the amount of energy gained via `rechargeQuanta`.
     * @param amount The new recharge amount.
     */
    function setRechargeAmount(uint32 amount) public onlyOwner {
        rechargeAmount = amount;
        emit ParametersUpdated("rechargeAmount", amount);
    }

    /**
     * @dev Allows the owner to withdraw accumulated ETH fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Recipient is the zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(recipient, balance);
    }

     // --- Utility/Library Inclusion (Standard, but necessary) ---
     // Include SafeMath or a similar library for arithmetic safety in production.
     // Solidity 0.8+ has built-in overflow checks, so SafeMath isn't strictly
     // necessary for *basic* arithmetic, but good practice for more complex ops.
     // We'll use simple arithmetic here, but acknowledge the need for care.
     // Using a simple Math library for min/max for clarity.
     library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
         function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
     }
}
```