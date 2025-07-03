Okay, this is an exciting challenge! Let's design a smart contract that simulates some concepts inspired by quantum mechanics for a unique on-chain treasure hunt game.

We'll create a system of "Quantum Nodes", each in a superposition of states. Players can apply "Quantum Gates" to these nodes to change their state distribution or "Measure" a node, collapsing its superposition to a single outcome based on probabilities. Nodes can be "Entangled", meaning measuring one affects the state of another. The "Treasure" is found when a specific configuration of measured node outcomes is achieved.

This uses concepts like superposition (represented by probability/weight distributions), state collapse (measurement), quantum gates (state transformations), and entanglement (correlated state changes). It's a simplified simulation, of course, as true quantum computation isn't possible on EVM, but it captures the spirit.

Let's outline the contract and its functions.

---

**Contract Name:** `QuantumTreasureHunt`

**Description:** A game contract where players interact with simulated quantum nodes by applying gates and performing measurements to achieve a target state configuration and claim a treasure. Nodes have states represented by weights in a superposition, are affected by gate transformations, collapse upon measurement based on probabilities, and can be entangled, causing correlated state changes.

**Outline:**

1.  **SPDX License and Pragma**
2.  **Error Definitions**
3.  **Structs**
    *   `QuantumNode`: Represents a node with its state weights, measured status, and outcome.
    *   `EntanglementRule`: Defines how measuring one node/outcome affects another node's state weights.
4.  **State Variables**
    *   Owner address
    *   Configuration locked status
    *   Mapping of Node ID to `QuantumNode`
    *   Mapping of Gate ID to Gate transformation matrix (`int[][]`)
    *   Mapping for Entanglement Rules (`measuredNodeId => measuredOutcome => targetNodeId => weightDeltas[]`)
    *   Mapping for the Treasure Target State (`nodeId => targetOutcome`)
    *   Treasure Reward amount
    *   Collected Fees
    *   Interaction Fees (`gateFee`, `measurementFee`)
    *   Total number of nodes
    *   Mapping to store player measurement outcomes for historical lookup (`nodeId => measuredOutcome`) - Note: Storing *all* historical outcomes for *all* players could be expensive. Let's store the *final* outcome of a measured node visible to anyone.
5.  **Events**
    *   `NodeAdded`
    *   `NodeStateSet`
    *   `EntanglementRuleAdded`
    *   `GateDefined`
    *   `TreasureStateSet`
    *   `ConfigurationLocked`
    *   `GateApplied`
    *   `NodeMeasured`
    *   `EntanglementEffectApplied`
    *   `TreasureClaimed`
    *   `FeesWithdrawn`
    *   `FeeUpdated`
6.  **Modifiers**
    *   `onlyOwner`
    *   `onlyIfConfigNotLocked`
    *   `onlyIfConfigLocked`
7.  **Internal Helper Functions**
    *   `_applyGateMatrix`: Applies a gate matrix transformation to a node's state weights.
    *   `_triggerEntanglementEffects`: Applies entanglement rules after a node is measured.
    *   `_calculateProbabilitiesAndPickOutcome`: Calculates probabilities from weights and picks an outcome using randomness.
8.  **Public/External Functions**
    *   **Admin & Configuration (onlyOwner, onlyIfConfigNotLocked):**
        *   `constructor`
        *   `addNode`
        *   `setNodeInitialState`
        *   `addEntanglementRule`
        *   `defineGateMatrix`
        *   `setTreasureTargetState`
        *   `setTreasureRewardAmount`
        *   `setGateFee`
        *   `setMeasurementFee`
        *   `lockConfiguration`
    *   **Admin & Utility (onlyOwner):**
        *   `withdrawFees`
        *   `transferOwnership`
        *   `renounceOwnership`
    *   **Player Interaction (payable):**
        *   `applyGate`
        *   `measureNode`
    *   **Game Logic & View:**
        *   `getNodeState` (view)
        *   `getTotalNodes` (view)
        *   `getGateMatrix` (view)
        *   `getTreasureTargetState` (view)
        *   `getEntanglementRule` (view)
        *   `getGateFee` (view)
        *   `getMeasurementFee` (view)
        *   `isConfigurationLocked` (view)
        *   `checkTreasureCondition` (view)
        *   `claimTreasure`

**Function Summary:**

1.  `constructor()`: Deploys the contract and sets the owner.
2.  `addNode(uint256 nodeId, uint256 numStates)`: Owner adds a quantum node with a specified number of possible states. Must be called before config is locked.
3.  `setNodeInitialState(uint256 nodeId, int256[] memory initialWeights)`: Owner sets the initial state weights for a node. The number of weights must match the node's `numStates`. Weights can be positive, negative, or zero, representing abstract amplitudes/potentials. Must be called before config is locked.
4.  `addEntanglementRule(uint256 measuredNodeId, uint256 measuredOutcome, uint256 targetNodeId, int256[] memory weightDeltas)`: Owner defines an entanglement rule: if `measuredNodeId` collapses to `measuredOutcome`, the `weightDeltas` are added to `targetNodeId`'s state weights. The delta array size must match the target node's `numStates`. Must be called before config is locked.
5.  `defineGateMatrix(uint256 gateId, int256[][] memory matrix)`: Owner defines a gate transformation matrix. The matrix must be square, and its dimensions must match the number of states the gate is intended for. This contract assumes gates are applied to nodes with a matching number of states. Must be called before config is locked.
6.  `setTreasureTargetState(uint256[] memory nodeIds, uint256[] memory targetOutcomes)`: Owner defines the configuration of measured node outcomes required to find the treasure. Arrays must be same length. Must be called before config is locked.
7.  `setTreasureRewardAmount(uint256 amount)`: Owner sets the amount of Ether (or tokens if modified) claimable as treasure. Must be called before config is locked.
8.  `setGateFee(uint256 amount)`: Owner sets the Ether fee required to call `applyGate`.
9.  `setMeasurementFee(uint256 amount)`: Owner sets the Ether fee required to call `measureNode`.
10. `lockConfiguration()`: Owner locks the configuration, preventing further changes to nodes, states, rules, gates, or treasure definition. Must be called before players can interact.
11. `withdrawFees()`: Owner can withdraw collected interaction fees.
12. `transferOwnership(address newOwner)`: Transfers contract ownership.
13. `renounceOwnership()`: Renounces contract ownership (irreversible).
14. `applyGate(uint256 nodeId, uint256 gateId)`: Payable function for a player to apply a defined gate to a specific node. Requires paying the `gateFee`. The gate matrix is applied to the node's current state weights. Cannot be applied to an already measured node.
15. `measureNode(uint256 nodeId)`: Payable function for a player to measure a specific node. Requires paying the `measurementFee`. Uses block data (simplified randomness) to collapse the node's superposition to a single outcome based on current weight probabilities. Triggers entanglement effects. Cannot be measured if already measured.
16. `getNodeState(uint256 nodeId)`: View function to get a node's current state weights, measured status, and measured outcome.
17. `getTotalNodes()`: View function returning the total number of nodes added.
18. `getGateMatrix(uint256 gateId)`: View function to retrieve a defined gate's transformation matrix.
19. `getTreasureTargetState()`: View function returning the required node IDs and their target outcomes for the treasure.
20. `getEntanglementRule(uint256 measuredNodeId, uint256 measuredOutcome, uint256 targetNodeId)`: View function to get the weight deltas for a specific entanglement rule.
21. `getGateFee()`: View function returning the current fee for applying a gate.
22. `getMeasurementFee()`: View function returning the current fee for measuring a node.
23. `isConfigurationLocked()`: View function returning the configuration locked status.
24. `checkTreasureCondition()`: View function for any player to check if the current state of measured nodes matches the treasure target state.
25. `claimTreasure()`: Allows any address that satisfies the `checkTreasureCondition` to claim the treasure reward. Can only be claimed once.

---

Let's implement the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumTreasureHunt
 * @dev A game contract simulating quantum mechanics concepts (superposition, gates, measurement, entanglement)
 *      for an on-chain treasure hunt. Players apply 'gates' to modify node states and 'measure' nodes
 *      to collapse their superposition. Entangled nodes influence each other upon measurement.
 *      A treasure is awarded for achieving a specific configuration of measured node outcomes.
 *
 * Outline:
 * 1. SPDX License and Pragma
 * 2. Error Definitions
 * 3. Structs (QuantumNode, EntanglementEffect)
 * 4. State Variables (Owner, config, nodes, gates, entanglement, treasure, fees)
 * 5. Events
 * 6. Modifiers
 * 7. Internal Helpers (_applyGateMatrix, _triggerEntanglementEffects, _calculateProbabilitiesAndPickOutcome)
 * 8. Public/External Functions (Admin, Configuration, Player Interaction, Game Logic, Utility)
 *
 * Function Summary:
 * 1. constructor(): Initializes contract, sets owner.
 * 2. addNode(uint256 nodeId, uint256 numStates): Owner adds a node.
 * 3. setNodeInitialState(uint256 nodeId, int256[] memory initialWeights): Owner sets initial state weights.
 * 4. addEntanglementRule(uint256 measuredNodeId, uint256 measuredOutcome, uint256 targetNodeId, int256[] memory weightDeltas): Owner defines an entanglement rule.
 * 5. defineGateMatrix(uint256 gateId, int256[][] memory matrix): Owner defines a gate transformation matrix.
 * 6. setTreasureTargetState(uint256[] memory nodeIds, uint256[] memory targetOutcomes): Owner defines the treasure condition.
 * 7. setTreasureRewardAmount(uint256 amount): Owner sets treasure reward.
 * 8. setGateFee(uint256 amount): Owner sets gate interaction fee.
 * 9. setMeasurementFee(uint256 amount): Owner sets measurement fee.
 * 10. lockConfiguration(): Owner locks config after setup.
 * 11. withdrawFees(): Owner withdraws collected fees.
 * 12. transferOwnership(address newOwner): Transfers ownership.
 * 13. renounceOwnership(): Renounces ownership.
 * 14. applyGate(uint256 nodeId, uint256 gateId): Player applies a gate (payable).
 * 15. measureNode(uint256 nodeId): Player measures a node (payable).
 * 16. getNodeState(uint256 nodeId): View node state info.
 * 17. getTotalNodes(): View total number of nodes.
 * 18. getGateMatrix(uint256 gateId): View a gate matrix.
 * 19. getTreasureTargetState(): View treasure condition.
 * 20. getEntanglementRule(uint256 measuredNodeId, uint256 measuredOutcome, uint256 targetNodeId): View an entanglement rule.
 * 21. getGateFee(): View gate fee.
 * 22. getMeasurementFee(): View measurement fee.
 * 23. isConfigurationLocked(): View config lock status.
 * 24. checkTreasureCondition(): View if treasure condition is met.
 * 25. claimTreasure(): Claim treasure if condition is met.
 */

contract QuantumTreasureHunt {

    // --- 2. Error Definitions ---
    error Unauthorized();
    error ConfigLocked();
    error ConfigNotLocked();
    error NodeNotFound(uint256 nodeId);
    error NodeAlreadyExists(uint256 nodeId);
    error NodeAlreadyMeasured(uint256 nodeId);
    error InvalidStateWeights(uint256 expectedStates, uint256 actualWeights);
    error GateNotFound(uint256 gateId);
    error InvalidGateMatrix(uint256 expectedDim, uint256 actualRows, uint256 actualCols);
    error GateDimensionMismatch(uint256 nodeStates, uint256 gateDim);
    error EntanglementRuleNotFound(uint256 measuredNodeId, uint256 measuredOutcome, uint256 targetNodeId);
    error InvalidEntanglementDelta(uint256 targetNodeId, uint256 expectedStates, uint256 actualDeltas);
    error TreasureStateMismatch(uint256 numNodes, uint256 numOutcomes);
    error ConfigurationIncomplete();
    error PaymentRequired(uint256 requiredAmount);
    error PaymentExcess(uint256 paidAmount, uint256 expectedAmount);
    error TreasureNotClaimable();
    error TreasureAlreadyClaimed();
    error InvalidRandomness(); // Placeholder for potential randomness issues

    // --- 3. Structs ---
    struct QuantumNode {
        uint256 id;
        uint256 numStates;
        int256[] stateWeights; // Represents amplitude/potential weights
        bool isMeasured;
        uint256 measuredOutcome; // The state index (0 to numStates-1) after measurement
        bool exists; // To check if a node ID has been added
    }

    // Simplified entanglement: Measuring node M in outcome O adds delta[] to target node T's weights
    struct EntanglementEffect {
        uint256 targetNodeId;
        int256[] weightDeltas;
    }

    // --- 4. State Variables ---
    address private _owner;
    bool private _configLocked = false;
    uint256 private _totalNodes = 0;

    mapping(uint256 => QuantumNode) public quantumNodes;
    mapping(uint256 => int256[][]) public gateMatrices; // gateId => matrix[output_state][input_state]
    // measuredNodeId => measuredOutcome => array of effects
    mapping(uint256 => mapping(uint256 => EntanglementEffect[])) public entanglementRules;

    // Treasure definition: nodeIds and their required measuredOutcome
    uint256[] private _treasureNodeIds;
    mapping(uint256 => uint256) private _treasureTargetState; // nodeId => targetOutcome

    uint256 public treasureRewardAmount = 0;
    uint256 public collectedFees = 0;
    uint256 public gateFee = 0;
    uint256 public measurementFee = 0;

    bool private _treasureClaimed = false;

    // --- 5. Events ---
    event NodeAdded(uint256 indexed nodeId, uint256 numStates);
    event NodeStateSet(uint256 indexed nodeId, int256[] initialWeights);
    event EntanglementRuleAdded(uint256 indexed measuredNodeId, uint256 measuredOutcome, uint256 indexed targetNodeId);
    event GateDefined(uint256 indexed gateId, uint256 dimensions);
    event TreasureStateSet(uint256[] nodeIds, uint256[] targetOutcomes);
    event ConfigurationLocked();
    event GateApplied(uint256 indexed nodeId, uint256 indexed gateId, address indexed player);
    event NodeMeasured(uint256 indexed nodeId, uint256 measuredOutcome, address indexed player, uint256 randomnessUsed);
    event EntanglementEffectApplied(uint256 indexed measuredNodeId, uint256 indexed targetNodeId, uint256 measuredOutcome);
    event TreasureClaimed(address indexed receiver, uint256 amount);
    event FeesWithdrawn(address indexed receiver, uint256 amount);
    event FeeUpdated(string feeType, uint256 amount);

    // --- 6. Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert Unauthorized();
        _;
    }

    modifier onlyIfConfigNotLocked() {
        if (_configLocked) revert ConfigLocked();
        _;
    }

    modifier onlyIfConfigLocked() {
        if (!_configLocked) revert ConfigNotLocked();
        _;
    }

    // --- 7. Internal Helper Functions ---

    /**
     * @dev Applies a gate matrix transformation to a node's state weights.
     *      new_weights[i] = sum(matrix[i][j] * old_weights[j]) for all j
     * @param node The node to apply the gate to.
     * @param gateMatrix The gate transformation matrix.
     */
    function _applyGateMatrix(QuantumNode storage node, int256[][] memory gateMatrix) internal {
        uint256 numStates = node.numStates;
        int256[] memory newWeights = new int256[](numStates);

        for (uint256 i = 0; i < numStates; i++) { // Output state index
            int256 sum = 0;
            for (uint256 j = 0; j < numStates; j++) { // Input state index
                // Handle potential overflow? For typical simulation, weights might not be astronomical.
                // Consider using SafeMath-like patterns for multiplication if necessary.
                sum += gateMatrix[i][j] * node.stateWeights[j];
            }
            newWeights[i] = sum;
        }
        node.stateWeights = newWeights;
    }

    /**
     * @dev Triggers entanglement effects for other nodes linked to the measured node.
     * @param measuredNodeId The ID of the node that was just measured.
     * @param measuredOutcome The outcome of the measurement.
     */
    function _triggerEntanglementEffects(uint256 measuredNodeId, uint256 measuredOutcome) internal {
        EntanglementEffect[] storage effects = entanglementRules[measuredNodeId][measuredOutcome];
        for (uint256 i = 0; i < effects.length; i++) {
            uint256 targetNodeId = effects[i].targetNodeId;
            int256[] memory deltas = effects[i].weightDeltas;

            QuantumNode storage targetNode = quantumNodes[targetNodeId];
            // Apply deltas only if target node exists and is not yet measured
            if (targetNode.exists && !targetNode.isMeasured) {
                if (targetNode.stateWeights.length != deltas.length) {
                     // This should not happen if setup functions validated correctly,
                     // but is a safeguard.
                     continue; // Skip invalid effect
                }
                for (uint256 j = 0; j < targetNode.stateWeights.length; j++) {
                    targetNode.stateWeights[j] += deltas[j];
                    // Consider minimum/maximum weight bounds if needed
                }
                emit EntanglementEffectApplied(measuredNodeId, targetNodeId, measuredOutcome);
            }
        }
    }

    /**
     * @dev Calculates probabilities from state weights (using squared magnitude concept)
     *      and picks an outcome based on a random number.
     *      Uses blockhash/timestamp as a simplified, potentially weak randomness source.
     *      DO NOT use this for high-value or security-critical applications.
     *      Chainlink VRF or similar is recommended for production randomness.
     * @param weights The state weights of the node.
     * @return The index of the chosen outcome state.
     */
    function _calculateProbabilitiesAndPickOutcome(int256[] memory weights) internal view returns (uint256) {
        uint256 numStates = weights.length;
        require(numStates > 0, "Node has no states");

        uint256[] memory squaredWeights = new uint256[](numStates);
        uint256 totalSquaredWeight = 0;

        for (uint256 i = 0; i < numStates; i++) {
            // Use absolute value for probability contribution from negative weights
            uint256 absWeight = uint256(weights[i] >= 0 ? weights[i] : -weights[i]);
            squaredWeights[i] = absWeight * absWeight; // Conceptually ~ amplitude squared
            unchecked {
                totalSquaredWeight += squaredWeights[i];
            }
        }

        if (totalSquaredWeight == 0) {
             // If all weights are zero, cannot determine probability.
             // This state might indicate an issue or be a game design choice.
             // Revert or default to state 0, depending on game logic.
             // Reverting to prevent unexpected behavior.
             revert InvalidRandomness(); // Or a specific ZeroTotalWeight error
        }

        // Use blockhash and timestamp for basic randomness
        // WARNING: Predictable source!
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));

        uint256 cumulativeWeight = 0;
        uint256 randomChoice = randomNumber % totalSquaredWeight;

        for (uint256 i = 0; i < numStates; i++) {
            cumulativeWeight += squaredWeights[i];
            if (randomChoice < cumulativeWeight) {
                return i; // This state is chosen
            }
        }

        // Should not reach here if totalSquaredWeight is > 0 and logic is correct,
        // but as a fallback, return the last state index.
        return numStates - 1;
    }


    // --- 8. Public/External Functions ---

    // --- Admin & Configuration ---

    /**
     * @dev Deploys the contract and sets the owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Adds a new quantum node to the system. Only callable by owner before config is locked.
     * @param nodeId The unique ID for the new node.
     * @param numStates The number of discrete states this node can be in superposition of.
     */
    function addNode(uint256 nodeId, uint256 numStates) external onlyOwner onlyIfConfigNotLocked {
        if (quantumNodes[nodeId].exists) revert NodeAlreadyExists(nodeId);
        if (numStates == 0) revert InvalidStateWeights(0, numStates); // Need at least one state

        quantumNodes[nodeId] = QuantumNode({
            id: nodeId,
            numStates: numStates,
            stateWeights: new int256[](numStates), // Initialize with zero weights
            isMeasured: false,
            measuredOutcome: 0, // Default, irrelevant until measured
            exists: true
        });
        _totalNodes++;
        emit NodeAdded(nodeId, numStates);
    }

    /**
     * @dev Sets the initial state weights for an existing node. Only callable by owner before config is locked.
     *      The size of initialWeights array must match the node's numStates.
     * @param nodeId The ID of the node.
     * @param initialWeights The initial weights for each state.
     */
    function setNodeInitialState(uint256 nodeId, int256[] memory initialWeights) external onlyOwner onlyIfConfigNotLocked {
        QuantumNode storage node = quantumNodes[nodeId];
        if (!node.exists) revert NodeNotFound(nodeId);
        if (node.numStates != initialWeights.length) {
            revert InvalidStateWeights(node.numStates, initialWeights.length);
        }
        node.stateWeights = initialWeights;
        emit NodeStateSet(nodeId, initialWeights);
    }

    /**
     * @dev Defines an entanglement rule: if `measuredNodeId` collapses to `measuredOutcome`,
     *      `weightDeltas` are added to `targetNodeId`'s state weights.
     *      Only callable by owner before config is locked.
     * @param measuredNodeId The ID of the node being measured.
     * @param measuredOutcome The specific outcome that triggers the effect.
     * @param targetNodeId The ID of the node whose weights are affected.
     * @param weightDeltas The int256 array of deltas to add to the target node's weights.
     */
    function addEntanglementRule(uint256 measuredNodeId, uint256 measuredOutcome, uint256 targetNodeId, int256[] memory weightDeltas) external onlyOwner onlyIfConfigNotLocked {
        if (!quantumNodes[measuredNodeId].exists) revert NodeNotFound(measuredNodeId);
        if (measuredOutcome >= quantumNodes[measuredNodeId].numStates) revert InvalidStateWeights(quantumNodes[measuredNodeId].numStates, measuredOutcome + 1);
        if (!quantumNodes[targetNodeId].exists) revert NodeNotFound(targetNodeId);
        if (quantumNodes[targetNodeId].numStates != weightDeltas.length) {
             revert InvalidEntanglementDelta(targetNodeId, quantumNodes[targetNodeId].numStates, weightDeltas.length);
        }

        entanglementRules[measuredNodeId][measuredOutcome].push(
            EntanglementEffect({
                targetNodeId: targetNodeId,
                weightDeltas: weightDeltas // Stores a copy of the deltas
            })
        );

        emit EntanglementRuleAdded(measuredNodeId, measuredOutcome, targetNodeId);
    }

    /**
     * @dev Defines a gate transformation matrix. Only callable by owner before config is locked.
     *      The matrix must be square (rows == cols) and non-empty.
     * @param gateId The unique ID for the gate.
     * @param matrix The 2D int256 array representing the gate matrix.
     */
    function defineGateMatrix(uint256 gateId, int256[][] memory matrix) external onlyOwner onlyIfConfigNotLocked {
        uint256 rows = matrix.length;
        if (rows == 0) revert InvalidGateMatrix(0, 0, 0);
        uint256 cols = matrix[0].length;
        if (rows != cols) revert InvalidGateMatrix(rows, rows, cols);

        gateMatrices[gateId] = matrix; // Stores a copy
        emit GateDefined(gateId, rows);
    }

    /**
     * @dev Sets the required measured outcomes for the treasure condition.
     *      The arrays nodeIds and targetOutcomes must have the same length.
     *      Only callable by owner before config is locked.
     * @param nodeIds The IDs of the nodes that must be measured.
     * @param targetOutcomes The required outcome for each corresponding node ID.
     */
    function setTreasureTargetState(uint256[] memory nodeIds, uint256[] memory targetOutcomes) external onlyOwner onlyIfConfigNotLocked {
        if (nodeIds.length != targetOutcomes.length) {
            revert TreasureStateMismatch(nodeIds.length, targetOutcomes.length);
        }
        // Clear previous target state
        delete _treasureNodeIds;
        // Note: Deleting from mapping doesn't shrink gas cost long term,
        // but it clears the values for checking. Re-setting mapping keys is fine.
        // A more gas-optimized approach might involve a linked list of treasure nodes.

        _treasureNodeIds = nodeIds;
        for (uint256 i = 0; i < nodeIds.length; i++) {
            _treasureTargetState[nodeIds[i]] = targetOutcomes[i];
            // Basic validation: check if node exists and target outcome is valid state
            if (!quantumNodes[nodeIds[i]].exists) revert NodeNotFound(nodeIds[i]);
            if (targetOutcomes[i] >= quantumNodes[nodeIds[i]].numStates) {
                 revert InvalidStateWeights(quantumNodes[nodeIds[i]].numStates, targetOutcomes[i] + 1);
            }
        }
        emit TreasureStateSet(nodeIds, targetOutcomes);
    }

    /**
     * @dev Sets the amount of Ether to be awarded as treasure. Only callable by owner before config is locked.
     * @param amount The amount in Wei.
     */
    function setTreasureRewardAmount(uint256 amount) external onlyOwner onlyIfConfigNotLocked {
        treasureRewardAmount = amount;
    }

    /**
     * @dev Sets the fee required to call `applyGate`.
     * @param amount The amount in Wei.
     */
    function setGateFee(uint256 amount) external onlyOwner {
        gateFee = amount;
        emit FeeUpdated("Gate", amount);
    }

    /**
     * @dev Sets the fee required to call `measureNode`.
     * @param amount The amount in Wei.
     */
    function setMeasurementFee(uint256 amount) external onlyOwner {
        measurementFee = amount;
        emit FeeUpdated("Measurement", amount);
    }

    /**
     * @dev Locks the configuration, preventing further changes to nodes, gates, rules, and treasure state.
     *      Must be called before players can interact via applyGate or measureNode.
     *      Basic check for minimum setup: at least one node and treasure condition defined.
     */
    function lockConfiguration() external onlyOwner onlyIfConfigNotLocked {
         if (_totalNodes == 0 || _treasureNodeIds.length == 0) {
             revert ConfigurationIncomplete();
         }
        _configLocked = true;
        emit ConfigurationLocked();
    }

    // --- Admin & Utility ---

    /**
     * @dev Allows the owner to withdraw collected fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = collectedFees;
        collectedFees = 0;
        // Use a low-level call to send Ether to prevent reentrancy issues
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed"); // Should handle this more gracefully in production
        emit FeesWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Unauthorized(); // Cannot transfer to zero address
        _owner = newOwner;
        // Standard OpenZeppelin Ownable emits OwnershipTransferred event.
        // For simplicity here, we won't add the OZ library, just the function.
    }

    /**
     * @dev Renounces ownership of the contract.
     *      The contract will not have an owner, and functions protected by onlyOwner will be inaccessible.
     */
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
         // Standard OpenZeppelin Ownable emits OwnershipTransferred event.
         // For simplicity here, we won't add the OZ library, just the function.
    }


    // --- Player Interaction ---

    /**
     * @dev Allows a player to apply a defined gate to a specific quantum node.
     *      Requires paying the defined `gateFee`. Cannot be applied to a measured node.
     * @param nodeId The ID of the node to apply the gate to.
     * @param gateId The ID of the gate to apply.
     */
    function applyGate(uint256 nodeId, uint256 gateId) external payable onlyIfConfigLocked {
        if (msg.value < gateFee) revert PaymentRequired(gateFee);
        if (msg.value > gateFee) revert PaymentExcess(msg.value, gateFee);

        collectedFees += msg.value;

        QuantumNode storage node = quantumNodes[nodeId];
        if (!node.exists) revert NodeNotFound(nodeId);
        if (node.isMeasured) revert NodeAlreadyMeasured(nodeId);

        int256[][] memory gateMatrix = gateMatrices[gateId];
        if (gateMatrix.length == 0) revert GateNotFound(gateId);

        uint256 gateDim = gateMatrix.length;
        if (node.numStates != gateDim) {
            revert GateDimensionMismatch(node.numStates, gateDim);
        }

        _applyGateMatrix(node, gateMatrix);

        emit GateApplied(nodeId, gateId, msg.sender);
    }

    /**
     * @dev Allows a player to measure a specific quantum node, collapsing its superposition.
     *      Requires paying the defined `measurementFee`. Cannot measure an already measured node.
     *      Triggers entanglement effects on other nodes.
     * @param nodeId The ID of the node to measure.
     */
    function measureNode(uint256 nodeId) external payable onlyIfConfigLocked {
        if (msg.value < measurementFee) revert PaymentRequired(measurementFee);
        if (msg.value > measurementFee) revert PaymentExcess(msg.value, measurementFee);

        collectedFees += msg.value;

        QuantumNode storage node = quantumNodes[nodeId];
        if (!node.exists) revert NodeNotFound(nodeId);
        if (node.isMeasured) revert NodeAlreadyMeasured(nodeId);

        // Calculate probabilities and pick outcome
        uint256 chosenOutcome = _calculateProbabilitiesAndPickOutcome(node.stateWeights);

        // Collapse state
        node.isMeasured = true;
        node.measuredOutcome = chosenOutcome;
        // Clear weights after measurement (optional, saves storage)
        delete node.stateWeights;

        emit NodeMeasured(nodeId, chosenOutcome, msg.sender, uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)))); // Emitting randomness used for transparency

        // Trigger entanglement effects
        _triggerEntanglementEffects(nodeId, chosenOutcome);
    }

    // --- Game Logic & View ---

    /**
     * @dev View function to get the current state information of a node.
     * @param nodeId The ID of the node.
     * @return numStates The total number of states for the node.
     * @return stateWeights The current state weights (empty array if measured).
     * @return isMeasured True if the node has been measured.
     * @return measuredOutcome The outcome state if measured (default 0 if not measured).
     */
    function getNodeState(uint256 nodeId) external view returns (
        uint256 numStates,
        int256[] memory stateWeights,
        bool isMeasured,
        uint256 measuredOutcome
    ) {
        QuantumNode storage node = quantumNodes[nodeId];
        if (!node.exists) revert NodeNotFound(nodeId);

        return (
            node.numStates,
            node.stateWeights, // Returns empty array if deleted after measurement
            node.isMeasured,
            node.measuredOutcome
        );
    }

    /**
     * @dev View function returning the total number of quantum nodes added to the system.
     */
    function getTotalNodes() external view returns (uint256) {
        return _totalNodes;
    }

    /**
     * @dev View function to retrieve the transformation matrix for a defined gate.
     * @param gateId The ID of the gate.
     * @return The 2D int256 array representing the gate matrix. Returns empty matrix if not found.
     */
    function getGateMatrix(uint256 gateId) external view returns (int256[][] memory) {
        // Returns a copy from storage mapping
        return gateMatrices[gateId];
    }

    /**
     * @dev View function returning the array of node IDs and their required outcomes for the treasure.
     * @return nodeIds Array of node IDs in the treasure condition.
     * @return targetOutcomes Array of required outcomes corresponding to the node IDs.
     */
    function getTreasureTargetState() external view returns (uint256[] memory nodeIds, uint256[] memory targetOutcomes) {
        uint256 len = _treasureNodeIds.length;
        uint256[] memory ids = new uint256[](len);
        uint256[] memory outcomes = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            ids[i] = _treasureNodeIds[i];
            outcomes[i] = _treasureTargetState[ids[i]];
        }
        return (ids, outcomes);
    }

     /**
     * @dev View function to get the entanglement effects triggered when a specific node measures a specific outcome.
     * @param measuredNodeId The ID of the node being measured.
     * @param measuredOutcome The outcome of the measurement.
     * @return An array of `EntanglementEffect` structs.
     */
    function getEntanglementRule(uint256 measuredNodeId, uint256 measuredOutcome) external view returns (EntanglementEffect[] memory) {
        // Returns a copy from storage mapping
        return entanglementRules[measuredNodeId][measuredOutcome];
    }


    /**
     * @dev View function returning the current fee required to apply a gate.
     */
    function getGateFee() external view returns (uint256) {
        return gateFee;
    }

    /**
     * @dev View function returning the current fee required to measure a node.
     */
    function getMeasurementFee() external view returns (uint256) {
        return measurementFee;
    }

    /**
     * @dev View function indicating whether the contract configuration has been locked.
     */
    function isConfigurationLocked() external view returns (bool) {
        return _configLocked;
    }

    /**
     * @dev Checks if the current state of measured nodes matches the treasure target state.
     *      Requires all nodes specified in the treasure condition to be measured,
     *      and their outcomes must match the target outcomes.
     * @return True if the treasure condition is met, false otherwise.
     */
    function checkTreasureCondition() public view returns (bool) {
        if (_treasureNodeIds.length == 0) return false; // No treasure defined

        for (uint256 i = 0; i < _treasureNodeIds.length; i++) {
            uint256 nodeId = _treasureNodeIds[i];
            uint256 requiredOutcome = _treasureTargetState[nodeId];

            QuantumNode storage node = quantumNodes[nodeId];
            // Node must exist, be measured, and the outcome must match
            if (!node.exists || !node.isMeasured || node.measuredOutcome != requiredOutcome) {
                return false; // Condition not met for this node
            }
        }
        // If all required nodes are measured with the correct outcomes
        return true;
    }

    /**
     * @dev Allows an address to claim the treasure reward if the `checkTreasureCondition` is true.
     *      Can only be claimed once.
     */
    function claimTreasure() external onlyIfConfigLocked {
        if (_treasureClaimed) revert TreasureAlreadyClaimed();
        if (!checkTreasureCondition()) revert TreasureNotClaimable();
        if (treasureRewardAmount == 0) revert TreasureNotClaimable(); // No reward set

        _treasureClaimed = true;
        uint256 amount = treasureRewardAmount;
        treasureRewardAmount = 0; // Prevent re-claiming implicitly via amount

        // Use a low-level call for the transfer
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Treasure claim failed"); // Should handle this more gracefully

        emit TreasureClaimed(msg.sender, amount);
    }
}
```