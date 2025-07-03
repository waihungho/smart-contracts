Okay, let's design a smart contract based on a "Quantum Flow Manager" concept. The idea is to define sequences of operations (flows) that can be instantiated, exist in different states (like superposition/pending), and be "observed" (triggered) based on certain conditions, potentially influencing or "entangling" with other instances.

This goes beyond simple task queues by incorporating conditional triggering based on external factors (time/block), state transitions managed internally, the ability to define reusable flow templates, and a mechanism for linking instances.

**Concept:** Quantum Flow Manager

**Core Idea:** Define reusable "flows" composed of sequential steps (external contract calls, value transfers). Create specific "instances" of these flows with unique trigger conditions (e.g., block number, timestamp). These instances exist in a "pending" state until "observed" (a function call checks conditions). If conditions are met, the instance "collapses" into an "Executing" state and runs the steps. Instances can be "linked" so that the successful completion of one *can* potentially trigger its linked counterparts if *they* are also ready.

**Outline:**

1.  **Pragma & Imports:** Solidity version, Ownable contract.
2.  **Events:** Log important actions (definition creation, instance creation, state changes, triggering, linking).
3.  **Enums:** Define possible states for a Flow Instance.
4.  **Structs:** Define `FlowStep`, `FlowDefinition`, and `FlowInstance`.
5.  **State Variables:** Mappings to store definitions and instances, arrays to track IDs for iteration, counters.
6.  **Modifiers:** Access control (`onlyOwner`, `whenNotExecuting`).
7.  **Constructor:** Initializes owner.
8.  **Flow Definition Functions (Manager Role):** Create, update, activate, deactivate definitions.
9.  **Flow Instance Functions (User Role):** Create instances from definitions, set/update conditions, cancel instances.
10. **Linking Functions ("Entanglement"):** Link and unlink flow instances.
11. **Observation/Execution Functions:** Check if an instance is ready, trigger execution, handle step execution, manage state transitions.
12. **Query Functions:** Get definitions, instance details, states, linked instances.
13. **Utility/Admin Functions:** Withdraw ETH, ownership transfer.

**Function Summary:**

1.  `defineFlow`: Create a new reusable flow definition.
2.  `updateFlowDefinition`: Modify the steps of an existing definition (owner only).
3.  `deactivateFlowDefinition`: Disable a definition, preventing new instances.
4.  `activateFlowDefinition`: Re-enable a definition.
5.  `getFlowDefinition`: Retrieve a specific flow definition.
6.  `doesFlowDefinitionExist`: Check if a definition ID exists.
7.  `getAllDefinitionIds`: Get all currently defined flow IDs.
8.  `createFlowInstance`: Create a concrete instance of a flow definition with initial data and optional trigger conditions.
9.  `setInstanceConditions`: Update the trigger conditions for a pending flow instance.
10. `cancelFlowInstance`: Cancel a flow instance before it's triggered.
11. `getInstanceData`: Retrieve the arbitrary data blob associated with an instance.
12. `setInstanceData`: Update the arbitrary data blob for a pending instance.
13. `getFlowInstanceState`: Get the current state of a flow instance.
14. `getAllInstanceIds`: Get all created instance IDs.
15. `linkInstances`: Create a reciprocal link between two flow instances.
16. `unlinkInstances`: Remove a reciprocal link between two flow instances.
17. `getLinkedInstances`: Get the list of instances linked to a given instance.
18. `canObserve`: Check if a specific instance meets its trigger conditions and is ready for observation.
19. `observeFlowInstance`: Attempt to trigger and execute a flow instance if its conditions are met. This is the core state-transitioning function.
20. `retryFailedStep`: Attempt to re-execute the specific step that caused a flow instance to fail, potentially allowing the flow to continue.
21. `getFailedStepIndex`: Get the index of the step that caused an instance failure.
22. `transferOwnership`: Transfer contract ownership.
23. `renounceOwnership`: Renounce contract ownership.
24. `withdrawETH`: Owner can withdraw ETH sent to the contract (e.g., from failed calls with value or accidental sends).
25. `receive`: Allow the contract to receive ETH (useful for flows that involve sending value).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Outline:
// 1. Pragma & Imports
// 2. Events
// 3. Enums
// 4. Structs
// 5. State Variables
// 6. Modifiers
// 7. Constructor
// 8. Flow Definition Functions
// 9. Flow Instance Functions
// 10. Linking Functions ("Entanglement")
// 11. Observation/Execution Functions
// 12. Query Functions
// 13. Utility/Admin Functions

// Function Summary:
// 1. defineFlow(bytes32 definitionId, string memory name, FlowStep[] memory steps): Create a new reusable flow definition.
// 2. updateFlowDefinition(bytes32 definitionId, FlowStep[] memory newSteps): Modify the steps of an existing definition (owner only).
// 3. deactivateFlowDefinition(bytes32 definitionId): Disable a definition, preventing new instances.
// 4. activateFlowDefinition(bytes32 definitionId): Re-enable a definition.
// 5. getFlowDefinition(bytes32 definitionId): Retrieve a specific flow definition.
// 6. doesFlowDefinitionExist(bytes32 definitionId): Check if a definition ID exists.
// 7. getAllDefinitionIds(): Get all currently defined flow IDs.
// 8. createFlowInstance(bytes32 definitionId, uint256 triggerBlock, uint256 triggerTimestamp, bytes memory initialData): Create a concrete instance of a flow definition.
// 9. setInstanceConditions(bytes32 instanceId, uint256 triggerBlock, uint256 triggerTimestamp): Update the trigger conditions for a pending flow instance.
// 10. cancelFlowInstance(bytes32 instanceId): Cancel a flow instance before it's triggered.
// 11. getInstanceData(bytes32 instanceId): Retrieve the arbitrary data blob associated with an instance.
// 12. setInstanceData(bytes32 instanceId, bytes memory newData): Update the arbitrary data blob for a pending instance.
// 13. getFlowInstanceState(bytes32 instanceId): Get the current state of a flow instance.
// 14. getAllInstanceIds(): Get all created instance IDs.
// 15. linkInstances(bytes32 instanceId1, bytes32 instanceId2): Create a reciprocal link between two flow instances.
// 16. unlinkInstances(bytes32 instanceId1, bytes32 instanceId2): Remove a reciprocal link between two flow instances.
// 17. getLinkedInstances(bytes32 instanceId): Get the list of instances linked to a given instance.
// 18. canObserve(bytes32 instanceId): Check if a specific instance meets its trigger conditions and is ready for observation.
// 19. observeFlowInstance(bytes32 instanceId): Attempt to trigger and execute a flow instance.
// 20. retryFailedStep(bytes32 instanceId): Attempt to re-execute the specific step that caused a flow instance to fail.
// 21. getFailedStepIndex(bytes32 instanceId): Get the index of the step that caused an instance failure.
// 22. transferOwnership(address newOwner): Transfer contract ownership.
// 23. renounceOwnership(): Renounce contract ownership.
// 24. withdrawETH(address payable recipient): Owner can withdraw ETH from the contract.
// 25. receive(): Allows the contract to receive ETH.

contract QuantumFlowManager is Ownable {
    using Address for address;

    // 2. Events
    event FlowDefinitionCreated(bytes32 indexed definitionId, string name, address indexed owner);
    event FlowDefinitionUpdated(bytes32 indexed definitionId);
    event FlowDefinitionStatusChanged(bytes32 indexed definitionId, bool isActive);

    event FlowInstanceCreated(bytes32 indexed instanceId, bytes32 indexed definitionId, address indexed creator);
    event FlowInstanceConditionsUpdated(bytes32 indexed instanceId, uint256 triggerBlock, uint256 triggerTimestamp);
    event FlowInstanceDataUpdated(bytes32 indexed instanceId);
    event FlowInstanceCancelled(bytes32 indexed instanceId);

    event FlowInstanceStateChanged(bytes32 indexed instanceId, FlowState newState, FlowState oldState);
    event FlowInstanceTriggered(bytes32 indexed instanceId);
    event FlowInstanceStepExecuted(bytes32 indexed instanceId, uint256 stepIndex, bool success);
    event FlowInstanceCompleted(bytes32 indexed instanceId);
    event FlowInstanceFailed(bytes32 indexed instanceId, uint256 failedStepIndex, bytes returnData);
    event FlowInstanceRetried(bytes32 indexed instanceId, uint256 retriedStepIndex);

    event InstancesLinked(bytes32 indexed instanceId1, bytes32 indexed instanceId2);
    event InstancesUnlinked(bytes32 indexed instanceId1, bytes32 indexed instanceId2);

    // 3. Enums
    enum FlowState {
        Undefined,   // Should ideally not be used
        Defined,     // Created but not ready/waiting for conditions
        Ready,       // Conditions met, waiting for observation/trigger
        Executing,   // Currently running steps
        Completed,   // Finished successfully
        Failed,      // Execution failed at a specific step
        Cancelled    // Explicitly cancelled
    }

    // 4. Structs
    struct FlowStep {
        address target;         // Target contract/address for the call
        bytes callData;         // Calldata for the target (includes method selector and arguments)
        uint256 ethValue;       // ETH to send with the call
        bool requireSuccess;    // If true, flow fails if this step fails
    }

    struct FlowDefinition {
        string name;            // Human-readable name
        FlowStep[] steps;       // Sequence of steps
        address owner;          // Creator of the definition
        bool isActive;          // Can new instances be created from this definition?
    }

    struct FlowInstance {
        bytes32 definitionId;   // Which definition this instance is based on
        FlowState state;        // Current state of the instance
        address creator;        // Who created this instance
        uint256 creationBlock;
        uint256 creationTimestamp;

        // Trigger Conditions (Instance is Ready when both are met or 0)
        uint256 triggerBlock;
        uint256 triggerTimestamp;

        bytes instanceData;     // Arbitrary data blob associated with this instance

        // Execution State
        uint256 currentStepIndex; // Index of the step currently being executed or next to execute
        uint256 failedStepIndex;  // Index of the step that caused failure (if state is Failed)

        // Linked Instances ("Entanglement")
        bytes32[] linkedInstances;
    }

    // 5. State Variables
    mapping(bytes32 => FlowDefinition) private s_flowDefinitions;
    bytes32[] private s_definitionIds; // To iterate through definition IDs

    mapping(bytes32 => FlowInstance) private s_flowInstances;
    bytes32[] private s_instanceIds; // To iterate through instance IDs

    // Mapping to track linked instances efficiently
    mapping(bytes32 => mapping(bytes32 => bool)) private s_linkedInstancesMap;

    // 6. Modifiers
    modifier whenNotExecuting(bytes32 _instanceId) {
        require(s_flowInstances[_instanceId].state != FlowState.Executing, "Flow: Instance is currently executing");
        _;
    }

    // 7. Constructor
    constructor() Ownable(msg.sender) {}

    // 25. receive
    // Allows the contract to receive ETH, which can be used for steps with ethValue.
    receive() external payable {}

    // --- 8. Flow Definition Functions (Owner Role) ---

    /// @notice Creates a new flow definition that can be instantiated later.
    /// @param definitionId A unique identifier for the flow definition.
    /// @param name A human-readable name for the definition.
    /// @param steps The sequence of steps for this flow.
    function defineFlow(bytes32 definitionId, string memory name, FlowStep[] memory steps) public onlyOwner {
        require(!s_flowDefinitions[definitionId].isActive, "Flow: Definition ID already exists or is active");
        require(bytes(name).length > 0, "Flow: Name cannot be empty");
        require(steps.length > 0, "Flow: Steps cannot be empty");

        s_flowDefinitions[definitionId] = FlowDefinition({
            name: name,
            steps: steps,
            owner: msg.sender,
            isActive: true
        });
        s_definitionIds.push(definitionId); // Add to list for iteration

        emit FlowDefinitionCreated(definitionId, name, msg.sender);
    }

    /// @notice Updates the steps of an existing flow definition.
    /// Can only be done by the definition owner while it's inactive.
    /// @param definitionId The ID of the definition to update.
    /// @param newSteps The new sequence of steps.
    function updateFlowDefinition(bytes32 definitionId, FlowStep[] memory newSteps) public {
        FlowDefinition storage definition = s_flowDefinitions[definitionId];
        require(definition.owner == msg.sender, "Flow: Not definition owner");
        require(!definition.isActive, "Flow: Definition must be inactive to update");
        require(newSteps.length > 0, "Flow: Steps cannot be empty");

        definition.steps = newSteps;
        emit FlowDefinitionUpdated(definitionId);
    }

    /// @notice Deactivates a flow definition, preventing new instances from being created.
    /// @param definitionId The ID of the definition to deactivate.
    function deactivateFlowDefinition(bytes32 definitionId) public onlyOwner {
        FlowDefinition storage definition = s_flowDefinitions[definitionId];
        require(definition.isActive, "Flow: Definition is already inactive");

        definition.isActive = false;
        emit FlowDefinitionStatusChanged(definitionId, false);
    }

    /// @notice Activates a flow definition, allowing new instances to be created.
    /// @param definitionId The ID of the definition to activate.
    function activateFlowDefinition(bytes32 definitionId) public onlyOwner {
        FlowDefinition storage definition = s_flowDefinitions[definitionId];
        require(!definition.isActive, "Flow: Definition is already active");
        // Definition must exist to be activated
        require(bytes(definition.name).length > 0 || definition.steps.length > 0, "Flow: Definition does not exist");

        definition.isActive = true;
        emit FlowDefinitionStatusChanged(definitionId, true);
    }

    /// @notice Retrieves a specific flow definition.
    /// @param definitionId The ID of the definition to retrieve.
    /// @return The flow definition struct.
    function getFlowDefinition(bytes32 definitionId) public view returns (FlowDefinition memory) {
        return s_flowDefinitions[definitionId];
    }

    /// @notice Checks if a flow definition exists and is active.
    /// @param definitionId The ID to check.
    /// @return True if the definition exists and is active, false otherwise.
    function doesFlowDefinitionExist(bytes32 definitionId) public view returns (bool) {
        return s_flowDefinitions[definitionId].isActive;
    }

     /// @notice Get all currently defined flow IDs.
     /// @return An array of all definition IDs.
     function getAllDefinitionIds() public view returns (bytes32[] memory) {
         return s_definitionIds;
     }


    // --- 9. Flow Instance Functions (User Role) ---

    /// @notice Creates a new instance of a defined flow.
    /// An instance can have specific trigger conditions and initial data.
    /// @param definitionId The ID of the flow definition to instantiate.
    /// @param triggerBlock The block number at or after which the instance can be observed (0 for no block condition).
    /// @param triggerTimestamp The timestamp at or after which the instance can be observed (0 for no time condition).
    /// @param initialData Arbitrary initial data associated with this instance.
    /// @return The unique ID of the created instance.
    function createFlowInstance(
        bytes32 definitionId,
        uint256 triggerBlock,
        uint256 triggerTimestamp,
        bytes memory initialData
    ) public returns (bytes32 instanceId) {
        require(s_flowDefinitions[definitionId].isActive, "Flow: Definition is not active");

        // Generate a unique instance ID
        instanceId = keccak256(abi.encodePacked(msg.sender, definitionId, block.timestamp, tx.origin, block.number));
        // Ensure ID is unique (highly unlikely to collide, but belt and suspenders)
        require(s_flowInstances[instanceId].state == FlowState.Undefined, "Flow: Instance ID collision");

        FlowState initialState = (triggerBlock == 0 && triggerTimestamp == 0) ? FlowState.Ready : FlowState.Defined;

        s_flowInstances[instanceId] = FlowInstance({
            definitionId: definitionId,
            state: initialState,
            creator: msg.sender,
            creationBlock: block.number,
            creationTimestamp: block.timestamp,
            triggerBlock: triggerBlock,
            triggerTimestamp: triggerTimestamp,
            instanceData: initialData,
            currentStepIndex: 0,
            failedStepIndex: 0, // 0 indicates no failure recorded
            linkedInstances: new bytes32[](0)
        });
         s_instanceIds.push(instanceId); // Add to list for iteration


        emit FlowInstanceCreated(instanceId, definitionId, msg.sender);
        emit FlowInstanceStateChanged(instanceId, initialState, FlowState.Undefined);
    }

    /// @notice Updates the trigger conditions for a flow instance.
    /// Can only be done by the instance creator or owner while in Defined or Ready state.
    /// @param instanceId The ID of the instance to update.
    /// @param triggerBlock The new trigger block number.
    /// @param triggerTimestamp The new trigger timestamp.
    function setInstanceConditions(
        bytes32 instanceId,
        uint256 triggerBlock,
        uint256 triggerTimestamp
    ) public {
        FlowInstance storage instance = s_flowInstances[instanceId];
        require(instance.state == FlowState.Defined || instance.state == FlowState.Ready, "Flow: Instance not in modifiable state");
        // Allow owner of definition or creator of instance to modify conditions
        FlowDefinition storage definition = s_flowDefinitions[instance.definitionId];
         require(msg.sender == instance.creator || msg.sender == definition.owner, "Flow: Not authorized to set conditions");


        instance.triggerBlock = triggerBlock;
        instance.triggerTimestamp = triggerTimestamp;

        // Update state based on new conditions
        FlowState oldState = instance.state;
        if (canObserve(instanceId)) {
             instance.state = FlowState.Ready;
             if (oldState != FlowState.Ready) emit FlowInstanceStateChanged(instanceId, FlowState.Ready, oldState);
        } else {
             instance.state = FlowState.Defined; // Revert to Defined if conditions unmet
             if (oldState != FlowState.Defined) emit FlowInstanceStateChanged(instanceId, FlowState.Defined, oldState);
        }


        emit FlowInstanceConditionsUpdated(instanceId, triggerBlock, triggerTimestamp);
    }

    /// @notice Cancels a flow instance. Can only be done by creator or owner while in Defined or Ready state.
    /// @param instanceId The ID of the instance to cancel.
    function cancelFlowInstance(bytes32 instanceId) public {
        FlowInstance storage instance = s_flowInstances[instanceId];
        require(instance.state == FlowState.Defined || instance.state == FlowState.Ready, "Flow: Instance not in modifiable state");
         FlowDefinition storage definition = s_flowDefinitions[instance.definitionId];
         require(msg.sender == instance.creator || msg.sender == definition.owner, "Flow: Not authorized to cancel instance");


        FlowState oldState = instance.state;
        instance.state = FlowState.Cancelled;
        emit FlowInstanceCancelled(instanceId);
        emit FlowInstanceStateChanged(instanceId, FlowState.Cancelled, oldState);

        // Optionally clear data/links to save gas if state is final like Cancelled
        // instance.instanceData = ""; // Clearing bytes costs gas, maybe not ideal
        // instance.linkedInstances = new bytes32[](0); // Clearing array costs gas
    }

    /// @notice Retrieves the arbitrary data blob for an instance.
    /// @param instanceId The ID of the instance.
    /// @return The instance data bytes.
    function getInstanceData(bytes32 instanceId) public view returns (bytes memory) {
        return s_flowInstances[instanceId].instanceData;
    }

     /// @notice Updates the arbitrary data blob for a pending instance.
     /// Can only be done by creator or owner while in Defined or Ready state.
     /// @param instanceId The ID of the instance.
     /// @param newData The new data bytes.
     function setInstanceData(bytes32 instanceId, bytes memory newData) public {
         FlowInstance storage instance = s_flowInstances[instanceId];
         require(instance.state == FlowState.Defined || instance.state == FlowState.Ready, "Flow: Instance not in modifiable state");
         FlowDefinition storage definition = s_flowDefinitions[instance.definitionId];
         require(msg.sender == instance.creator || msg.sender == definition.owner, "Flow: Not authorized to set data");

         instance.instanceData = newData;
         emit FlowInstanceDataUpdated(instanceId);
     }


    /// @notice Get the current state of a flow instance.
    /// @param instanceId The ID of the instance.
    /// @return The current FlowState enum value.
    function getFlowInstanceState(bytes32 instanceId) public view returns (FlowState) {
        return s_flowInstances[instanceId].state;
    }

     /// @notice Get all created instance IDs.
     /// @return An array of all instance IDs.
     function getAllInstanceIds() public view returns (bytes32[] memory) {
         return s_instanceIds;
     }


    // --- 10. Linking Functions ("Entanglement") ---

    /// @notice Creates a reciprocal link between two flow instances.
    /// Linking allows the successful completion of one instance to potentially trigger linked ones if they are ready.
    /// Can only link instances that exist and are not yet completed/failed/cancelled/executing.
    /// @param instanceId1 The ID of the first instance.
    /// @param instanceId2 The ID of the second instance.
    function linkInstances(bytes32 instanceId1, bytes32 instanceId2) public {
        require(instanceId1 != instanceId2, "Flow: Cannot link an instance to itself");

        FlowInstance storage instance1 = s_flowInstances[instanceId1];
        FlowInstance storage instance2 = s_flowInstances[instanceId2];

        require(instance1.state > FlowState.Undefined && instance1.state < FlowState.Executing, "Flow: Instance 1 not linkable state");
        require(instance2.state > FlowState.Undefined && instance2.state < FlowState.Executing, "Flow: Instance 2 not linkable state");

        // Check if already linked
        require(!s_linkedInstancesMap[instanceId1][instanceId2], "Flow: Instances already linked");

        // Add links reciprocally
        instance1.linkedInstances.push(instanceId2);
        s_linkedInstancesMap[instanceId1][instanceId2] = true;

        instance2.linkedInstances.push(instanceId1);
        s_linkedInstancesMap[instanceId2][instanceId1] = true;

        emit InstancesLinked(instanceId1, instanceId2);
    }

    /// @notice Removes a reciprocal link between two flow instances.
    /// @param instanceId1 The ID of the first instance.
    /// @param instanceId2 The ID of the second instance.
    function unlinkInstances(bytes32 instanceId1, bytes32 instanceId2) public {
        require(instanceId1 != instanceId2, "Flow: Cannot unlink from itself");

        FlowInstance storage instance1 = s_flowInstances[instanceId1];
        FlowInstance storage instance2 = s_flowInstances[instanceId2];

        // Check if linked
        require(s_linkedInstancesMap[instanceId1][instanceId2], "Flow: Instances not linked");

        // Remove links reciprocally - inefficient way, better to use a linked list or swap-and-pop if order doesn't matter
        // Using swap-and-pop for gas efficiency
        for (uint i = 0; i < instance1.linkedInstances.length; i++) {
            if (instance1.linkedInstances[i] == instanceId2) {
                instance1.linkedInstances[i] = instance1.linkedInstances[instance1.linkedInstances.length - 1];
                instance1.linkedInstances.pop();
                break;
            }
        }

        for (uint i = 0; i < instance2.linkedInstances.length; i++) {
            if (instance2.linkedInstances[i] == instanceId1) {
                instance2.linkedInstances[i] = instance2.linkedInstances[instance2.linkedInstances.length - 1];
                instance2.linkedInstances.pop();
                break;
            }
        }

        s_linkedInstancesMap[instanceId1][instanceId2] = false;
        s_linkedInstancesMap[instanceId2][instanceId1] = false;

        emit InstancesUnlinked(instanceId1, instanceId2);
    }

    /// @notice Gets the list of instance IDs linked to a given instance.
    /// @param instanceId The ID of the instance.
    /// @return An array of linked instance IDs.
    function getLinkedInstances(bytes32 instanceId) public view returns (bytes32[] memory) {
        // Ensure instance exists (state > Undefined)
        require(s_flowInstances[instanceId].state > FlowState.Undefined, "Flow: Instance does not exist");
        return s_flowInstances[instanceId].linkedInstances;
    }


    // --- 11. Observation/Execution Functions ---

    /// @notice Checks if a specific instance meets its trigger conditions and is in the Ready state.
    /// @param instanceId The ID of the instance to check.
    /// @return True if the instance is Ready and conditions are met, false otherwise.
    function canObserve(bytes32 instanceId) public view returns (bool) {
        FlowInstance storage instance = s_flowInstances[instanceId];

        if (instance.state != FlowState.Ready) {
            return false;
        }

        // Check block condition (if set)
        if (instance.triggerBlock > 0 && block.number < instance.triggerBlock) {
            return false;
        }

        // Check timestamp condition (if set)
        if (instance.triggerTimestamp > 0 && block.timestamp < instance.triggerTimestamp) {
            return false;
        }

        return true;
    }

    /// @notice Attempts to trigger and execute a flow instance.
    /// Can be called by anyone. Checks if `canObserve` is true.
    /// If ready, executes the steps sequentially. Manages state transitions.
    /// @param instanceId The ID of the instance to observe/trigger.
    function observeFlowInstance(bytes32 instanceId) public whenNotExecuting(instanceId) {
        FlowInstance storage instance = s_flowInstances[instanceId];
        FlowDefinition storage definition = s_flowDefinitions[instance.definitionId];

        require(canObserve(instanceId), "Flow: Instance not ready for observation");
        require(definition.steps.length > 0, "Flow: Definition has no steps");

        // Transition to Executing state
        emit FlowInstanceStateChanged(instanceId, FlowState.Executing, instance.state);
        instance.state = FlowState.Executing;
        instance.failedStepIndex = 0; // Reset failed index

        emit FlowInstanceTriggered(instanceId);

        // Execute steps sequentially
        for (uint256 i = instance.currentStepIndex; i < definition.steps.length; ) { // Use while loop structure for flexibility with i increment
             FlowStep memory step = definition.steps[i];

             bool success;
             bytes memory returnData;

            // Use low-level call for flexibility
            (success, returnData) = step.target.call{value: step.ethValue}(step.callData);

             emit FlowInstanceStepExecuted(instanceId, i, success);

             if (!success && step.requireSuccess) {
                 // Step failed and was required for success - instance fails
                 instance.state = FlowState.Failed;
                 instance.failedStepIndex = i + 1; // Store 1-based index for easier user understanding (or 0-based if preferred)
                 instance.currentStepIndex = i; // Stop at the failed step
                 emit FlowInstanceFailed(instanceId, instance.failedStepIndex, returnData);
                 emit FlowInstanceStateChanged(instanceId, FlowState.Failed, FlowState.Executing);
                 return; // Stop execution
             } else if (!success && !step.requireSuccess) {
                 // Step failed but wasn't required - log and continue
                 // No state change, instance.failedStepIndex remains 0
             }
             // else: success is true, continue

             unchecked {
                 ++i; // Manually increment counter
             }
             instance.currentStepIndex = i; // Save progress
        }

        // All steps executed successfully
        instance.state = FlowState.Completed;
        instance.failedStepIndex = 0; // Ensure 0
        instance.currentStepIndex = definition.steps.length; // Point to end
        emit FlowInstanceCompleted(instanceId);
        emit FlowInstanceStateChanged(instanceId, FlowState.Completed, FlowState.Executing);

        // --- "Entanglement" Triggering ---
        // After successful completion, check linked instances and trigger any that are also Ready
        // This is a form of cascading trigger based on successful observation/collapse
        for (uint i = 0; i < instance.linkedInstances.length; i++) {
            bytes32 linkedId = instance.linkedInstances[i];
            // Check if the linked instance exists and is ready to be observed
            // We use a try-catch block in case the linked instance contract is destroyed or observation fails for gas reasons etc.
            // It's important this cascading trigger doesn't revert the parent transaction if a linked one fails.
            try this.observeFlowInstance(linkedId) {} catch {} // Attempt to observe, ignore errors
        }
    }

    /// @notice Attempts to re-execute the specific step that caused a flow instance to fail.
    /// If successful, it attempts to continue execution from the next step.
    /// Can only be called by the instance creator or definition owner.
    /// @param instanceId The ID of the failed instance.
    function retryFailedStep(bytes32 instanceId) public whenNotExecuting(instanceId) {
        FlowInstance storage instance = s_flowInstances[instanceId];
        require(instance.state == FlowState.Failed, "Flow: Instance is not in a failed state");
        FlowDefinition storage definition = s_flowDefinitions[instance.definitionId];
        require(msg.sender == instance.creator || msg.sender == definition.owner, "Flow: Not authorized to retry instance");

        uint256 stepIndexToRetry = instance.failedStepIndex > 0 ? instance.failedStepIndex - 1 : 0; // Get 0-based index
        require(stepIndexToRetry < definition.steps.length, "Flow: Invalid failed step index");

        // Transition to Executing state for retry
        emit FlowInstanceStateChanged(instanceId, FlowState.Executing, instance.state);
        instance.state = FlowState.Executing;
        instance.currentStepIndex = stepIndexToRetry; // Start execution from the failed step

        emit FlowInstanceRetried(instanceId, stepIndexToRetry);

        // Attempt to execute the failed step and continue
         for (uint256 i = instance.currentStepIndex; i < definition.steps.length; ) {
             FlowStep memory step = definition.steps[i];

             bool success;
             bytes memory returnData;

             (success, returnData) = step.target.call{value: step.ethValue}(step.callData);

             emit FlowInstanceStepExecuted(instanceId, i, success);

             if (!success && step.requireSuccess) {
                 // Step failed again and was required
                 instance.state = FlowState.Failed;
                 instance.failedStepIndex = i + 1; // Update failed index
                 instance.currentStepIndex = i; // Stop at the failed step
                 emit FlowInstanceFailed(instanceId, instance.failedStepIndex, returnData);
                 emit FlowInstanceStateChanged(instanceId, FlowState.Failed, FlowState.Executing);
                 return; // Stop execution
             } else if (!success && !step.requireSuccess) {
                 // Step failed but not required, continue
                 // failedStepIndex remains 0 from retry start
             }
             // else: success is true, continue

             unchecked {
                 ++i;
             }
             instance.currentStepIndex = i; // Save progress
         }

        // All steps executed successfully after retry
        instance.state = FlowState.Completed;
        instance.failedStepIndex = 0; // Ensure 0
        instance.currentStepIndex = definition.steps.length;
        emit FlowInstanceCompleted(instanceId);
        emit FlowInstanceStateChanged(instanceId, FlowState.Completed, FlowState.Executing);

        // --- "Entanglement" Triggering After Retry Success ---
        // Same logic as successful observation - trigger linked instances if they are ready
        for (uint i = 0; i < instance.linkedInstances.length; i++) {
            bytes32 linkedId = instance.linkedInstances[i];
             try this.observeFlowInstance(linkedId) {} catch {} // Attempt to observe, ignore errors
        }
    }

     /// @notice Get the 1-based index of the step that caused an instance failure.
     /// Returns 0 if the instance is not in a failed state or failed at step 0.
     /// @param instanceId The ID of the instance.
     /// @return The 1-based index of the failed step, or 0.
    function getFailedStepIndex(bytes32 instanceId) public view returns (uint256) {
        return s_flowInstances[instanceId].failedStepIndex;
    }


    // --- 22-24. Utility/Admin Functions ---

    /// @notice Allows the contract owner to withdraw trapped Ether.
    /// @param recipient The address to send the Ether to.
    function withdrawETH(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Flow: Invalid recipient address");
        uint256 balance = address(this).balance;
        require(balance > 0, "Flow: No ETH balance to withdraw");
        recipient.transfer(balance); // Use transfer for basic safety check
    }

    // Inherits transferOwnership and renounceOwnership from Ownable
}
```