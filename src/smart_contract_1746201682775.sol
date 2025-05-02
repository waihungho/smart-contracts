Okay, let's design a smart contract based on the concept of a "Quantum Canvas". This will involve elements of digital ownership, state transitions inspired by quantum mechanics (superposition, observation, entanglement - simulated on a deterministic blockchain), and dynamic properties.

We'll create a canvas grid where users can place "Quanta". Each Quanta can exist in a state of superposition (representing multiple possibilities) until observed, at which point its state collapses. Quanta can also be "entangled", meaning observing one might affect the state of another.

This concept is creative, uses state complexity, simulates abstract ideas, and involves digital ownership without being a standard ERC-721 or simple token/DAO.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumCanvas
 * @dev A smart contract simulating a grid-based "Quantum Canvas" where users
 * can place and interact with "Quanta". Quanta have properties inspired by
 * quantum mechanics: superposition, observation leading to state collapse,
 * and entanglement. This contract is not a standard token or NFT,
 * but manages ownership of digital entities (Quanta) with complex, dynamic states.
 */

/**
 * @notice Outline:
 * 1. Data Structures: Define the structure for a Quanta and potentially entanglement groups.
 * 2. State Variables: Define the canvas dimensions, quanta data, ownership mappings, entanglement data, global parameters (decay, cooldown).
 * 3. Events: Define events for key state changes and actions.
 * 4. Modifiers: Define access control and state condition modifiers.
 * 5. Core Logic:
 *    - Placing Quanta (minting/creation).
 *    - Managing Quanta states (superposition, observation, collapse).
 *    - Managing Entanglement (linking quanta, synchronous state changes).
 *    - Ownership transfer and burning.
 *    - Updating Quanta properties (name, position if allowed).
 *    - Global canvas interactions (fluctuations, parameter changes).
 *    - Read functions for querying state.
 */

/**
 * @notice Function Summary: (Total > 20 functions)
 *
 * Administration & Setup:
 * 1.  constructor(uint256 _width, uint256 _height, uint256 _decayRate, uint256 _obsCooldown): Initializes the canvas dimensions and global parameters.
 * 2.  setDecayRate(uint256 _newRate): Admin function to update the rate at which superposition becomes unstable.
 * 3.  setObservationCooldown(uint256 _newCooldown): Admin function to update the time required between observations of a single quanta.
 * 4.  transferAdmin(address _newAdmin): Admin function to transfer ownership of the contract admin role.
 *
 * Quanta Creation & Management:
 * 5.  placeQuanta(uint256 _x, uint256 _y, bytes[] memory _potentialStates, string memory _name): Allows a user to place a new Quanta on the canvas in superposition.
 * 6.  addPotentialState(uint256 _quantaId, bytes memory _state): Adds a potential state to an existing Quanta's possibilities.
 * 7.  removePotentialState(uint256 _quantaId, bytes memory _state): Removes a specific potential state from a Quanta.
 * 8.  updateQuantaName(uint256 _quantaId, string memory _newName): Allows the owner to rename their Quanta.
 * 9.  updateQuantaCoordinates(uint256 _quantaId, uint256 _newX, uint256 _newY): Allows the owner to move their Quanta to a new empty coordinate.
 *
 * State Interaction (Superposition & Observation):
 * 10. observeQuanta(uint256 _quantaId, bytes32 _userSeed): Triggers the collapse of a superposed Quanta to one of its potential states based on a pseudo-random outcome. Respects cooldown.
 * 11. revertSuperposition(uint256 _quantaId): Allows the owner to force an observed Quanta back into a superposed state.
 * 12. checkAndDecaySuperposition(uint256 _quantaId): Allows anyone to trigger a decay check on a superposed Quanta based on elapsed time and decay rate. Might randomly collapse or alter states.
 * 13. triggerGlobalFluctuation(bytes32 _userSeed): Admin function to potentially trigger state changes or decay effects across *all* superposed quanta based on global parameters and randomness. (Might be gas intensive).
 *
 * Entanglement:
 * 14. entangleQuanta(uint256 _quantaId1, uint256 _quantaId2): Creates an entanglement bond between two owned Quanta.
 * 15. breakEntanglement(uint256 _quantaId): Breaks the entanglement bond for a specific Quanta and its group.
 * 16. observeEntangledGroup(uint256 _entanglementId, bytes32 _userSeed): Observes *all* quanta within an entangled group, collapsing their states potentially interdependently (simulated).
 *
 * Ownership & Lifecycle:
 * 17. transferQuanta(address _to, uint256 _quantaId): Transfers ownership of a Quanta. Handles associated data (coords, owner mapping).
 * 18. burnQuanta(uint256 _quantaId): Destroys a Quanta. Handles associated data (coords, owner mapping, entanglement).
 *
 * Read Functions (Querying State):
 * 19. getQuantaInfo(uint256 _quantaId): Returns all details for a specific Quanta.
 * 20. getQuantaByCoord(uint256 _x, uint256 _y): Returns the Quanta ID at a given coordinate, or 0 if empty.
 * 21. getQuantaByOwner(address _owner): Returns a list of Quanta IDs owned by an address.
 * 22. getEntangledGroup(uint256 _entanglementId): Returns a list of Quanta IDs belonging to an entanglement group.
 * 23. getCanvasDimensions(): Returns the canvas width and height.
 * 24. getTotalQuantaCount(): Returns the total number of placed Quanta.
 * 25. getQuantaPotentialStates(uint256 _quantaId): Returns the potential states of a Quanta.
 * 26. getQuantaCurrentState(uint256 _quantaId): Returns the current collapsed state of a Quanta (empty if superposed).
 * 27. getQuantaObservationData(uint256 _quantaId): Returns the last observed timestamp and cooldown.
 */

contract QuantumCanvas {

    address public admin;

    uint256 public canvasWidth;
    uint256 public canvasHeight;

    // Global parameters affecting Quanta behavior
    uint256 public decayRate;          // Influences checkAndDecaySuperposition (e.g., block difference)
    uint256 public observationCooldown; // Minimum time (in seconds) between observations

    struct Quanta {
        address owner;
        uint256 id; // Redundant with mapping key, but useful within struct
        uint256 x;
        uint256 y;
        bool isSuperposed;
        bytes[] potentialStates; // Possible outcomes (e.g., color hex, parameters)
        bytes currentState;      // Actual state after observation (empty if superposed)
        uint256 lastObserved;    // Timestamp of last observation
        uint256 entanglementId;  // ID linking entangled quanta (0 if not entangled)
        string name;
        uint256 placedBlock;     // Block number when placed, for decay calculations
    }

    // Mapping from Quanta ID to Quanta struct
    mapping(uint256 => Quanta) private quanta;
    uint256 private _quantaCounter; // Counter for unique Quanta IDs

    // Mapping from coordinates (packed) to Quanta ID
    // Packing coordinates: (x * canvasWidth) + y
    mapping(uint256 => uint256) private quantaByCoord;

    // Mapping from owner address to list of Quanta IDs they own
    mapping(address => uint256[]) private quantaByOwner;

    // Mapping from entanglement ID to list of Quanta IDs
    mapping(uint256 => uint256[]) private entangledGroups;
    uint256 private _entanglementCounter; // Counter for unique entanglement IDs

    // --- Events ---

    event QuantaPlaced(uint256 quantaId, address owner, uint256 x, uint256 y, string name);
    event StateAdded(uint256 quantaId, bytes state);
    event PotentialStateRemoved(uint256 quantaId, bytes state);
    event QuantaObserved(uint256 quantaId, bytes selectedState, uint256 timestamp);
    event SuperpositionReverted(uint256 quantaId);
    event QuantaEntangled(uint256 entanglementId, uint256 quantaId1, uint256 quantaId2);
    event EntanglementBroken(uint256 entanglementId, uint256 quantaId);
    event QuantaTransferred(uint256 quantaId, address from, address to);
    event QuantaBurned(uint256 quantaId, address owner);
    event NameUpdated(uint256 quantaId, string newName);
    event CoordinatesUpdated(uint256 quantaId, uint256 oldX, uint256 oldY, uint256 newX, uint256 newY);
    event DecayTriggered(uint256 quantaId, string outcome); // e.g., "collapsed", "states altered", "no effect"
    event GlobalFluctuationTriggered(address initiator, uint256 affectedCount);
    event DecayRateUpdated(uint256 newRate);
    event ObservationCooldownUpdated(uint256 newCooldown);
    event AdminTransferred(address oldAdmin, address newAdmin);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    modifier quantaExists(uint256 _quantaId) {
        require(quanta[_quantaId].owner != address(0), "Quanta does not exist");
        _;
    }

    modifier isOwnerOfQuanta(uint256 _quantaId) {
        require(quanta[_quantaId].owner == msg.sender, "Not owner of Quanta");
        _;
    }

    modifier whenSuperposed(uint256 _quantaId) {
        require(quanta[_quantaId].isSuperposed, "Quanta is not superposed");
        _;
    }

    modifier whenNotSuperposed(uint256 _quantaId) {
        require(!quanta[_quantaId].isSuperposed, "Quanta is superposed");
        _;
    }

    modifier coordIsEmpty(uint256 _x, uint256 _y) {
        require(_x < canvasWidth && _y < canvasHeight, "Coordinates out of bounds");
        require(quantaByCoord[packCoords(_x, _y)] == 0, "Coordinate already occupied");
        _;
    }

    // --- Internal Helpers ---

    function packCoords(uint256 _x, uint256 _y) internal view returns (uint256) {
        return (_x * canvasWidth) + _y;
    }

    function unpackCoords(uint256 _packedCoords) internal view returns (uint256 x, uint256 y) {
         x = _packedCoords / canvasWidth;
         y = _packedCoords % canvasWidth; // This assumes width > 0, which is enforced
    }

    // Helper to remove quanta ID from an owner's list
    function _removeQuantaFromOwner(address _owner, uint256 _quantaId) internal {
        uint256[] storage ownerQuanta = quantaByOwner[_owner];
        for (uint256 i = 0; i < ownerQuanta.length; i++) {
            if (ownerQuanta[i] == _quantaId) {
                // Swap with the last element and pop
                ownerQuanta[i] = ownerQuanta[ownerQuanta.length - 1];
                ownerQuanta.pop();
                break;
            }
        }
    }

     // Helper to remove quanta ID from an entangled group
    function _removeQuantaFromEntangledGroup(uint256 _entanglementId, uint256 _quantaId) internal {
         uint256[] storage group = entangledGroups[_entanglementId];
         for (uint256 i = 0; i < group.length; i++) {
             if (group[i] == _quantaId) {
                 // Swap with the last element and pop
                 group[i] = group[group.length - 1];
                 group.pop();
                 break;
             }
         }
         // If the group is now size 1, break the entanglement for the last member too
         if (group.length == 1) {
             quanta[group[0]].entanglementId = 0;
             delete entangledGroups[_entanglementId]; // Clean up the group entry
         } else if (group.length == 0) {
             delete entangledGroups[_entanglementId]; // Clean up empty group entry
         }
    }

    // Pseudo-randomness helper (WARNING: On-chain randomness is insecure for high-value outcomes)
    // Do NOT rely on this for cryptographically secure outcomes.
    // It's sufficient for simulating non-deterministic behavior in a low-stakes context.
    function _pseudoRandomChoice(uint256 _inputEntropy, uint256 _maxIndex) internal pure returns (uint256) {
        if (_maxIndex == 0) return 0;
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _inputEntropy)));
        return seed % (_maxIndex + 1);
    }

    // --- Constructor ---

    constructor(uint256 _width, uint256 _height, uint256 _decayRate, uint256 _obsCooldown) {
        require(_width > 0 && _height > 0, "Canvas dimensions must be positive");
        admin = msg.sender;
        canvasWidth = _width;
        canvasHeight = _height;
        decayRate = _decayRate;
        observationCooldown = _obsCooldown;
        _quantaCounter = 0;
        _entanglementCounter = 0;
    }

    // --- Admin Functions ---

    /**
     * @notice Updates the rate at which superposition becomes unstable.
     * @param _newRate The new decay rate (arbitrary unit, e.g., blocks or time delta).
     */
    function setDecayRate(uint256 _newRate) external onlyAdmin {
        decayRate = _newRate;
        emit DecayRateUpdated(_newRate);
    }

    /**
     * @notice Updates the minimum time required between observations of a single quanta.
     * @param _newCooldown The new cooldown period in seconds.
     */
    function setObservationCooldown(uint256 _newCooldown) external onlyAdmin {
        observationCooldown = _newCooldown;
        emit ObservationCooldownUpdated(_newCooldown);
    }

    /**
     * @notice Transfers the admin role to a new address.
     * @param _newAdmin The address of the new admin.
     */
    function transferAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin cannot be zero address");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminTransferred(oldAdmin, _newAdmin);
    }

    // --- Quanta Creation & Management ---

    /**
     * @notice Places a new Quanta on the canvas in a superposed state.
     * @param _x The x-coordinate (0-indexed).
     * @param _y The y-coordinate (0-indexed).
     * @param _potentialStates An array of possible states (e.g., color bytes). Must have at least one state.
     * @param _name A descriptive name for the Quanta.
     */
    function placeQuanta(uint256 _x, uint256 _y, bytes[] memory _potentialStates, string memory _name) external coordIsEmpty(_x, _y) {
        require(_potentialStates.length > 0, "Quanta must have at least one potential state");

        _quantaCounter++;
        uint256 newId = _quantaCounter;
        uint256 packed = packCoords(_x, _y);

        quanta[newId] = Quanta({
            owner: msg.sender,
            id: newId,
            x: _x,
            y: _y,
            isSuperposed: true,
            potentialStates: _potentialStates,
            currentState: bytes(""), // Empty when superposed
            lastObserved: 0,
            entanglementId: 0,
            name: _name,
            placedBlock: block.number
        });

        quantaByCoord[packed] = newId;
        quantaByOwner[msg.sender].push(newId);

        emit QuantaPlaced(newId, msg.sender, _x, _y, _name);
    }

    /**
     * @notice Adds a potential state to an existing Quanta.
     * @param _quantaId The ID of the Quanta.
     * @param _state The state bytes to add.
     */
    function addPotentialState(uint256 _quantaId, bytes memory _state) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) {
         quanta[_quantaId].potentialStates.push(_state);
         emit StateAdded(_quantaId, _state);
    }

    /**
     * @notice Removes a specific potential state from a Quanta.
     * @param _quantaId The ID of the Quanta.
     * @param _state The state bytes to remove.
     */
    function removePotentialState(uint256 _quantaId, bytes memory _state) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) {
        Quanta storage q = quanta[_quantaId];
        require(q.potentialStates.length > 1, "Quanta must retain at least one potential state");

        bool found = false;
        for (uint256 i = 0; i < q.potentialStates.length; i++) {
            if (keccak256(q.potentialStates[i]) == keccak256(_state)) {
                // Found the state, remove it
                q.potentialStates[i] = q.potentialStates[q.potentialStates.length - 1];
                q.potentialStates.pop();
                found = true;
                break; // Assuming unique states, exit after first found
            }
        }
        require(found, "State not found in potential states");
        emit PotentialStateRemoved(_quantaId, _state);
    }

     /**
      * @notice Updates the name of a Quanta.
      * @param _quantaId The ID of the Quanta.
      * @param _newName The new name for the Quanta.
      */
    function updateQuantaName(uint256 _quantaId, string memory _newName) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) {
        quanta[_quantaId].name = _newName;
        emit NameUpdated(_quantaId, _newName);
    }

    /**
     * @notice Allows the owner to move their Quanta to a new empty coordinate.
     * @param _quantaId The ID of the Quanta.
     * @param _newX The new x-coordinate.
     * @param _newY The new y-coordinate.
     */
    function updateQuantaCoordinates(uint256 _quantaId, uint256 _newX, uint256 _newY) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) coordIsEmpty(_newX, _newY) {
        Quanta storage q = quanta[_quantaId];
        uint256 oldPacked = packCoords(q.x, q.y);
        uint256 newPacked = packCoords(_newX, _newY);

        // Clear old position
        quantaByCoord[oldPacked] = 0;

        // Set new position
        q.x = _newX;
        q.y = _newY;
        quantaByCoord[newPacked] = _quantaId;

        emit CoordinatesUpdated(_quantaId, unpackCoords(oldPacked).x, unpackCoords(oldPacked).y, _newX, _newY);
    }


    // --- State Interaction ---

    /**
     * @notice Observes a superposed Quanta, collapsing its state.
     * Can be called by anyone, subject to cooldown.
     * @param _quantaId The ID of the Quanta to observe.
     * @param _userSeed A user-provided seed for pseudo-randomness.
     */
    function observeQuanta(uint256 _quantaId, bytes32 _userSeed) external quantaExists(_quantaId) whenSuperposed(_quantaId) {
        Quanta storage q = quanta[_quantaId];
        require(block.timestamp >= q.lastObserved + observationCooldown, "Observation cooldown in effect");
        require(q.potentialStates.length > 0, "Quanta has no potential states to collapse to");

        // Simulate collapse using pseudo-randomness
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _userSeed, q.id)));
        uint256 chosenIndex = randomFactor % q.potentialStates.length;
        q.currentState = q.potentialStates[chosenIndex];
        q.isSuperposed = false;
        q.lastObserved = block.timestamp;

        emit QuantaObserved(_quantaId, q.currentState, block.timestamp);

        // If entangled, trigger observation for the whole group (simple model: they all collapse based on *this* observation's randomness)
        if (q.entanglementId != 0) {
             uint256[] memory group = entangledGroups[q.entanglementId];
             bytes32 groupSeed = keccak256(abi.encodePacked(_userSeed, q.id, block.timestamp)); // Incorporate initiator's quanta and time
             for(uint256 i = 0; i < group.length; i++){
                 uint256 memberId = group[i];
                 if(memberId != _quantaId && quanta[memberId].isSuperposed){
                     // Collapse other entangled superposed quanta using a derived seed
                     uint256 memberRandomFactor = uint256(keccak256(abi.encodePacked(groupSeed, memberId)));
                     uint256 memberChosenIndex = memberRandomFactor % quanta[memberId].potentialStates.length;
                     quanta[memberId].currentState = quanta[memberId].potentialStates[memberChosenIndex];
                     quanta[memberId].isSuperposed = false;
                     quanta[memberId].lastObserved = block.timestamp;
                     emit QuantaObserved(memberId, quanta[memberId].currentState, block.timestamp);
                 }
             }
        }
    }

    /**
     * @notice Allows the owner to revert an observed Quanta back into superposition.
     * Clears the current state.
     * @param _quantaId The ID of the Quanta to revert.
     */
    function revertSuperposition(uint256 _quantaId) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) whenNotSuperposed(_quantaId) {
        Quanta storage q = quanta[_quantaId];
        q.isSuperposed = true;
        q.currentState = bytes(""); // Clear the collapsed state
        q.lastObserved = block.timestamp; // Optional: reset timer on reversion
        q.placedBlock = block.number; // Optional: reset decay timer on reversion

        emit SuperpositionReverted(_quantaId);
    }

    /**
     * @notice Allows anyone to trigger a decay check on a superposed Quanta.
     * Based on how long it's been superposed and the decay rate, it might
     * randomly collapse, lose potential states, or remain unchanged.
     * @param _quantaId The ID of the Quanta to check for decay.
     */
    function checkAndDecaySuperposition(uint256 _quantaId) external quantaExists(_quantaId) whenSuperposed(_quantaId) {
         Quanta storage q = quanta[_quantaId];
         uint256 blocksElapsed = block.number - q.placedBlock; // Using block number for decay

         if (blocksElapsed > decayRate) {
             // Increased probability of decay effect
             uint256 decayChance = blocksElapsed / decayRate; // Simple scaling factor
             bytes32 decaySeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _quantaId, blocksElapsed));
             uint256 outcome = uint256(decaySeed) % (100 / decayChance + 1); // Higher chance means smaller divisor

             if (outcome == 0) { // Small chance to collapse randomly
                 bytes32 collapseSeed = keccak256(abi.encodePacked(decaySeed, "collapse"));
                 uint256 chosenIndex = uint256(collapseSeed) % q.potentialStates.length;
                 q.currentState = q.potentialStates[chosenIndex];
                 q.isSuperposed = false;
                 q.lastObserved = block.timestamp;
                 emit DecayTriggered(_quantaId, "collapsed");
                 emit QuantaObserved(_quantaId, q.currentState, block.timestamp);

                 // Decay can also trigger entangled collapse (a different outcome than direct observation)
                 if (q.entanglementId != 0) {
                      uint256[] memory group = entangledGroups[q.entanglementId];
                      bytes32 groupSeed = keccak256(abi.encodePacked(decaySeed, "group_decay"));
                      for(uint256 i = 0; i < group.length; i++){
                          uint256 memberId = group[i];
                          if(memberId != _quantaId && quanta[memberId].isSuperposed){
                              uint256 memberRandomFactor = uint256(keccak256(abi.encodePacked(groupSeed, memberId)));
                              uint256 memberChosenIndex = memberRandomFactor % quanta[memberId].potentialStates.length;
                              quanta[memberId].currentState = quanta[memberId].potentialStates[memberChosenIndex];
                              quanta[memberId].isSuperposed = false;
                              quanta[memberId].lastObserved = block.timestamp;
                              emit DecayTriggered(memberId, "collapsed_due_to_entangled_decay");
                              emit QuantaObserved(memberId, quanta[memberId].currentState, block.timestamp);
                          }
                      }
                 }

             } else if (outcome <= 5) { // Slightly higher chance to lose a potential state
                  if (q.potentialStates.length > 1) {
                      bytes32 removeSeed = keccak256(abi.encodePacked(decaySeed, "remove"));
                      uint256 removeIndex = uint256(removeSeed) % q.potentialStates.length;
                      bytes memory removedState = q.potentialStates[removeIndex];
                      q.potentialStates[removeIndex] = q.potentialStates[q.potentialStates.length - 1];
                      q.potentialStates.pop();
                      emit DecayTriggered(_quantaId, "state_removed");
                      emit PotentialStateRemoved(_quantaId, removedState);
                  } else {
                      emit DecayTriggered(_quantaId, "decay_attempt_no_effect"); // Cannot remove last state
                  }
             } else {
                  emit DecayTriggered(_quantaId, "decay_attempt_no_effect"); // No significant decay effect this time
             }
         } else {
             emit DecayTriggered(_quantaId, "not_enough_elapsed");
         }
    }

    /**
     * @notice Admin function to trigger a fluctuation across the canvas.
     * Randomly checks *some* superposed quanta (limited by gas/iteration)
     * and applies a decay-like effect.
     * WARNING: This can be gas-intensive if there are many superposed quanta.
     * @param _userSeed A seed for global pseudo-randomness.
     */
    function triggerGlobalFluctuation(bytes32 _userSeed) external onlyAdmin {
         // Simple implementation: Iterate through the first N quanta (limit to avoid hitting block gas limit)
         // A more robust implementation might use a cursor or process in batches off-chain.
         uint256 limit = 100; // Process maximum 100 quanta per call
         uint256 affectedCount = 0;
         uint256 startId = _quantaCounter > limit ? _quantaCounter - limit + 1 : 1;

         for (uint256 i = startId; i <= _quantaCounter; i++) {
             if (quanta[i].owner != address(0) && quanta[i].isSuperposed) {
                 uint256 blocksElapsed = block.number - quanta[i].placedBlock;
                 if (blocksElapsed > decayRate) { // Only consider quanta eligible for decay
                     bytes32 fluctuationSeed = keccak256(abi.encodePacked(_userSeed, block.timestamp, block.difficulty, i));
                     uint256 outcome = uint256(fluctuationSeed) % 10; // Simplified randomness for global effect

                     if (outcome < 2) { // Low chance of collapse
                        bytes32 collapseSeed = keccak256(abi.encodePacked(fluctuationSeed, "global_collapse"));
                        uint256 chosenIndex = uint256(collapseSeed) % quanta[i].potentialStates.length;
                        quanta[i].currentState = quanta[i].potentialStates[chosenIndex];
                        quanta[i].isSuperposed = false;
                        quanta[i].lastObserved = block.timestamp;
                        emit DecayTriggered(i, "global_fluctuation_collapsed");
                        emit QuantaObserved(i, quanta[i].currentState, block.timestamp);
                        // Note: Global collapse doesn't cascade through entanglement in this simple model
                        affectedCount++;
                     } else if (outcome < 4) { // Low chance to lose a state
                         if (quanta[i].potentialStates.length > 1) {
                            bytes32 removeSeed = keccak256(abi.encodePacked(fluctuationSeed, "global_remove"));
                            uint256 removeIndex = uint256(removeSeed) % quanta[i].potentialStates.length;
                            bytes memory removedState = quanta[i].potentialStates[removeIndex];
                            quanta[i].potentialStates[removeIndex] = quanta[i].potentialStates[quanta[i].potentialStates.length - 1];
                            quanta[i].potentialStates.pop();
                            emit DecayTriggered(i, "global_fluctuation_state_removed");
                            emit PotentialStateRemoved(i, removedState);
                            affectedCount++;
                         }
                     }
                 }
             }
             if (affectedCount >= limit) break; // Stop processing after limit
         }
         emit GlobalFluctuationTriggered(msg.sender, affectedCount);
    }


    // --- Entanglement ---

    /**
     * @notice Creates an entanglement bond between two owned, non-entangled Quanta.
     * They must be superposed? Let's allow entanglement regardless of superposition,
     * but the coupled observation effect only applies when they *are* superposed.
     * @param _quantaId1 The ID of the first Quanta.
     * @param _quantaId2 The ID of the second Quanta.
     */
    function entangleQuanta(uint256 _quantaId1, uint256 _quantaId2) external quantaExists(_quantaId1) quantaExists(_quantaId2) {
        require(_quantaId1 != _quantaId2, "Cannot entangle a Quanta with itself");
        require(quanta[_quantaId1].owner == msg.sender && quanta[_quantaId2].owner == msg.sender, "Must own both Quanta to entangle");
        require(quanta[_quantaId1].entanglementId == 0 && quanta[_quantaId2].entanglementId == 0, "Both Quanta must not be already entangled");

        _entanglementCounter++;
        uint256 newEntanglementId = _entanglementCounter;

        quanta[_quantaId1].entanglementId = newEntanglementId;
        quanta[_quantaId2].entanglementId = newEntanglementId;

        entangledGroups[newEntanglementId].push(_quantaId1);
        entangledGroups[newEntanglementId].push(_quantaId2);

        emit QuantaEntangled(newEntanglementId, _quantaId1, _quantaId2);
    }

    /**
     * @notice Breaks the entanglement bond for a specific Quanta.
     * If the group size becomes 1, the last Quanta is also disentangled.
     * @param _quantaId The ID of the Quanta to disentangle.
     */
    function breakEntanglement(uint256 _quantaId) external quantaExists(_quantaId) {
        require(quanta[_quantaId].entanglementId != 0, "Quanta is not entangled");
        require(quanta[_quantaId].owner == msg.sender, "Only owner can break entanglement"); // Or allow anyone? Owner seems safer.

        uint256 entanglementId = quanta[_quantaId].entanglementId;
        quanta[_quantaId].entanglementId = 0;

        _removeQuantaFromEntangledGroup(entanglementId, _quantaId); // Helper handles group cleanup

        emit EntanglementBroken(entanglementId, _quantaId);
    }

     /**
      * @notice Observes all superposed quanta within a specific entanglement group.
      * Requires calling user to own at least one quanta in the group.
      * @param _entanglementId The ID of the entanglement group.
      * @param _userSeed A user-provided seed for pseudo-randomness.
      */
    function observeEntangledGroup(uint256 _entanglementId, bytes32 _userSeed) external {
         uint256[] storage group = entangledGroups[_entanglementId];
         require(group.length > 1, "Entanglement group is not valid or too small");

         bool callerOwnsOne = false;
         for(uint256 i = 0; i < group.length; i++){
             if(quanta[group[i]].owner == msg.sender){
                 callerOwnsOne = true;
                 break;
             }
         }
         require(callerOwnsOne, "Must own at least one Quanta in the group to observe it");

         bytes32 groupSeed = keccak256(abi.encodePacked(_userSeed, _entanglementId, block.timestamp)); // Seed for the group observation

         for(uint256 i = 0; i < group.length; i++){
             uint256 memberId = group[i];
             Quanta storage member = quanta[memberId];

             // Check cooldown for *each* member individually, but only proceed if at least one member is ready?
             // Or require ALL to be ready? Requiring all is simpler.
             // Let's require *at least one* ready, and only observe those that are ready and superposed.
             // This might lead to partial collapse, which is interesting.

             if(member.isSuperposed && block.timestamp >= member.lastObserved + observationCooldown){
                 uint256 memberRandomFactor = uint256(keccak256(abi.encodePacked(groupSeed, memberId))); // Use group seed + member ID for deterministic randomness within the group
                 uint256 chosenIndex = memberRandomFactor % member.potentialStates.length;
                 member.currentState = member.potentialStates[chosenIndex];
                 member.isSuperposed = false;
                 member.lastObserved = block.timestamp;
                 emit QuantaObserved(memberId, member.currentState, block.timestamp);
             }
         }
         // Note: No specific event for group observation itself, individual QuantaObserved events suffice.
    }


    // --- Ownership & Lifecycle ---

    /**
     * @notice Transfers ownership of a Quanta to a new address.
     * @param _to The recipient address.
     * @param _quantaId The ID of the Quanta to transfer.
     */
    function transferQuanta(address _to, uint256 _quantaId) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) {
        require(_to != address(0), "Recipient cannot be zero address");
        require(_to != msg.sender, "Cannot transfer to self");

        address from = msg.sender;
        Quanta storage q = quanta[_quantaId];

        // Update owner mapping
        _removeQuantaFromOwner(from, _quantaId);
        quantaByOwner[_to].push(_quantaId);

        // Update quanta owner
        q.owner = _to;

        emit QuantaTransferred(_quantaId, from, _to);
    }

    /**
     * @notice Burns (destroys) a Quanta.
     * @param _quantaId The ID of the Quanta to burn.
     */
    function burnQuanta(uint256 _quantaId) external quantaExists(_quantaId) isOwnerOfQuanta(_quantaId) {
        address owner = msg.sender;
        Quanta storage q = quanta[_quantaId];

        // Handle entanglement first
        if (q.entanglementId != 0) {
            _removeQuantaFromEntangledGroup(q.entanglementId, _quantaId);
        }

        // Remove from owner's list
        _removeQuantaFromOwner(owner, _quantaId);

        // Clear coordinate mapping
        quantaByCoord[packCoords(q.x, q.y)] = 0;

        // Delete Quanta data
        delete quanta[_quantaId];

        emit QuantaBurned(_quantaId, owner);
    }


    // --- Read Functions ---

    /**
     * @notice Returns all details for a specific Quanta.
     * @param _quantaId The ID of the Quanta.
     * @return owner The owner's address.
     * @return id The Quanta ID.
     * @return x The x-coordinate.
     * @return y The y-coordinate.
     * @return isSuperposed Whether the Quanta is superposed.
     * @return currentState The current state (empty if superposed).
     * @return lastObserved The timestamp of the last observation.
     * @return entanglementId The ID of the entanglement group (0 if none).
     * @return name The name of the Quanta.
     * @return placedBlock The block number when placed.
     */
    function getQuantaInfo(uint256 _quantaId)
        external
        view
        quantaExists(_quantaId)
        returns (
            address owner,
            uint256 id,
            uint256 x,
            uint256 y,
            bool isSuperposed,
            bytes memory currentState,
            uint256 lastObserved,
            uint256 entanglementId,
            string memory name,
            uint256 placedBlock
        )
    {
        Quanta storage q = quanta[_quantaId];
        return (
            q.owner,
            q.id,
            q.x,
            q.y,
            q.isSuperposed,
            q.currentState,
            q.lastObserved,
            q.entanglementId,
            q.name,
            q.placedBlock
        );
    }

    /**
     * @notice Returns the Quanta ID at a given coordinate.
     * @param _x The x-coordinate.
     * @param _y The y-coordinate.
     * @return The Quanta ID (0 if the coordinate is empty or out of bounds).
     */
    function getQuantaByCoord(uint256 _x, uint256 _y) external view returns (uint256) {
         if (_x >= canvasWidth || _y >= canvasHeight) {
             return 0; // Out of bounds
         }
         return quantaByCoord[packCoords(_x, _y)];
    }

     /**
      * @notice Returns a list of Quanta IDs owned by an address.
      * @param _owner The owner's address.
      * @return A dynamic array of Quanta IDs.
      */
    function getQuantaByOwner(address _owner) external view returns (uint256[] memory) {
        return quantaByOwner[_owner];
    }

    /**
     * @notice Returns a list of Quanta IDs belonging to an entanglement group.
     * @param _entanglementId The ID of the entanglement group.
     * @return A dynamic array of Quanta IDs in the group.
     */
    function getEntangledGroup(uint256 _entanglementId) external view returns (uint256[] memory) {
        return entangledGroups[_entanglementId];
    }

    /**
     * @notice Returns the canvas dimensions.
     * @return width The canvas width.
     * @return height The canvas height.
     */
    function getCanvasDimensions() external view returns (uint256 width, uint256 height) {
        return (canvasWidth, canvasHeight);
    }

    /**
     * @notice Returns the total number of Quanta placed on the canvas.
     * @return The total count.
     */
    function getTotalQuantaCount() external view returns (uint256) {
        return _quantaCounter;
    }

    /**
     * @notice Returns the potential states of a Quanta.
     * @param _quantaId The ID of the Quanta.
     * @return An array of bytes representing potential states.
     */
    function getQuantaPotentialStates(uint256 _quantaId) external view quantaExists(_quantaId) returns (bytes[] memory) {
        return quanta[_quantaId].potentialStates;
    }

     /**
      * @notice Returns the current collapsed state of a Quanta.
      * @param _quantaId The ID of the Quanta.
      * @return The current state bytes (empty if superposed).
      */
    function getQuantaCurrentState(uint256 _quantaId) external view quantaExists(_quantaId) returns (bytes memory) {
        return quanta[_quantaId].currentState;
    }

    /**
     * @notice Returns observation-related data for a Quanta.
     * @param _quantaId The ID of the Quanta.
     * @return lastObserved The timestamp of the last observation.
     * @return observationCooldown The required cooldown period.
     */
    function getQuantaObservationData(uint256 _quantaId) external view quantaExists(_quantaId) returns (uint256 lastObserved, uint256 observationCooldown) {
        Quanta storage q = quanta[_quantaId];
        return (q.lastObserved, this.observationCooldown()); // Use the latest contract cooldown value
    }

    // --- Fallback/Receive ---
    // Consider adding receive() or fallback() if you want the contract to receive ether,
    // although this contract's core logic doesn't inherently require it.
    // receive() external payable {}
    // fallback() external payable {}

}
```