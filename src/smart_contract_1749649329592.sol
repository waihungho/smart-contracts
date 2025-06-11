Okay, let's create a smart contract that manages divergent states or "realities", allowing for branching, merging, and collapsing of these states based on predefined logic or parameters passed as data. This concept is inspired by ideas from quantum mechanics or parallel universes, applied metaphorically to blockchain state management. We'll call it `QuantumLeapFactory`.

This contract will act as a factory that creates and manages these "Reality" instances, which are represented as structs holding state data, properties, and lifecycle information.

---

**Contract Name:** `QuantumLeapFactory`

**Concept:** Manages divergent states or "realities" on the blockchain. Allows users to create a primary reality, branch new realities from existing ones, update state and properties within a reality, track interactions, propose/execute merges between realities, initiate/finalize collapses of realities (choosing an outcome), and abandon realities. The "logic" for merging or collapsing is represented by data passed to functions, allowing for flexibility while keeping core execution on-chain.

**Outline:**

1.  **State Definitions:**
    *   Enum for Reality Status (`Active`, `Merged`, `Collapsed`, `Abandoned`).
    *   Struct `Reality` to hold state data, properties, parent/child relationships, status, ownership, etc.
2.  **Storage:**
    *   Mapping to store `Reality` structs by ID.
    *   Mapping to track child realities for each parent.
    *   Mapping to track realities owned by an address.
    *   Counters for total realities and realities per owner.
    *   Contract owner address.
3.  **Events:** To signal key state changes (creation, branching, merging, collapsing, state updates, etc.).
4.  **Modifiers:** Access control (`onlyOwner`, `onlyRealityOwner`, status checks).
5.  **Core Factory Functions:** Create the prime reality, manage the contract itself.
6.  **Reality Lifecycle Functions:** Create branches, merge, collapse, abandon.
7.  **Reality Interaction Functions:** Update state data, manage properties, track contributors, transfer ownership.
8.  **Query Functions:** Retrieve reality details, status, relationships, properties, counts.
9.  **Rule/Logic Hinting Functions:** Set data that influences merge/collapse outcomes.
10. **Value Tracking:** Simple mechanism to track a numerical value within a reality.

**Function Summary:**

1.  `constructor()`: Initializes the contract with an owner.
2.  `createPrimeReality(bytes initialData)`: Creates the very first reality.
3.  `branchReality(uint256 parentID, bytes branchData)`: Creates a new reality inheriting state hints from a parent.
4.  `updateRealityStateData(uint256 realityID, bytes newState)`: Modifies the core `stateData` of an active reality.
5.  `addRealityProperty(uint256 realityID, string key, bytes value)`: Adds a new dynamic property to an active reality.
6.  `updateRealityProperty(uint256 realityID, string key, bytes value)`: Updates an existing property of an active reality.
7.  `removeRealityProperty(uint256 realityID, string key)`: Removes a dynamic property from an active reality.
8.  `trackRealityValue(uint256 realityID, uint256 amount)`: Adds value to the `trackedValue` of an active reality.
9.  `addContributor(uint256 realityID, address contributor)`: Records an address as a contributor to a reality.
10. `transferRealityOwnership(uint256 realityID, address newOwner)`: Transfers ownership of a reality.
11. `setMergeLogicHint(uint256 realityID, bytes hintData)`: Sets data that guides a potential merge operation involving this reality.
12. `setCollapseOutcomeHint(uint256 realityID, bytes hintData)`: Sets data that suggests the outcome when this reality is collapsed.
13. `proposeAndExecuteMerge(uint256 realityID1, uint256 realityID2, bytes mergeLogicData)`: Executes a merge operation between two realities based on provided data and hints. (Example logic: Copies state from one to the other, marks one as Merged).
14. `initiateCollapseProcess(uint256 realityID)`: Marks a reality as ready for collapse.
15. `finalizeCollapseOutcome(uint256 realityID, bytes executionParameters)`: Executes the final outcome for a collapsed reality based on hints and parameters. (Example logic: Emits an event with a winning address derived from hint).
16. `abandonReality(uint256 realityID)`: Marks a reality as abandoned.
17. `getRealityDetails(uint256 realityID)`: Retrieves basic details of a reality struct.
18. `getRealityStatus(uint256 realityID)`: Gets the status of a reality.
19. `isRealityActive(uint256 realityID)`: Checks if a reality is currently active.
20. `getParentReality(uint256 realityID)`: Gets the parent reality ID.
21. `listChildRealities(uint256 parentID)`: Lists the IDs of realities branched from a parent.
22. `getRealityProperty(uint256 realityID, string key)`: Retrieves the value of a specific property.
23. `getRealityPropertyKeys(uint256 realityID)`: Lists all property keys for a reality.
24. `getTrackedRealityValue(uint256 realityID)`: Gets the current tracked value for a reality.
25. `getContributors(uint256 realityID)`: Lists addresses that have contributed to a reality. (Returns an array of addresses).
26. `getTotalRealitiesCount()`: Gets the total number of realities ever created.
27. `getOwnedRealitiesCount(address owner)`: Gets the number of realities owned by an address.
28. `checkAncestry(uint256 childID, uint256 potentialAncestorID)`: Checks if a reality is an ancestor of another.
29. `getRealityCreationBlock(uint256 realityID)`: Gets the block number when the reality was created.
30. `getLastInteractionBlock(uint256 realityID)`: Gets the block number of the last state/property interaction.
31. `setMetadataURI(uint256 realityID, string uri)`: Sets an off-chain metadata URI for a reality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title QuantumLeapFactory
 * @author YourNameHere
 * @notice A factory contract for managing divergent states or "realities" on the blockchain.
 * Realities can be created, branched, updated, merged, collapsed, or abandoned.
 * The interpretation of state data, properties, and merge/collapse logic is external
 * to the core contract logic but guided by data stored within the Reality struct.
 *
 * Outline:
 * 1. State Definitions (Enum, Struct)
 * 2. Storage Variables
 * 3. Events
 * 4. Modifiers
 * 5. Constructor
 * 6. Core Factory Functions (createPrimeReality)
 * 7. Reality Lifecycle Functions (branch, merge, collapse, abandon)
 * 8. Reality Interaction Functions (state, properties, value, contributors, ownership, metadata)
 * 9. Query Functions (get details, status, properties, counts, relationships)
 * 10. Rule/Logic Hinting Functions
 *
 * Function Summary:
 * 1. constructor(): Initializes contract owner.
 * 2. createPrimeReality(bytes initialData): Creates the initial reality state.
 * 3. branchReality(uint256 parentID, bytes branchData): Forks a new reality from an existing one.
 * 4. updateRealityStateData(uint256 realityID, bytes newState): Modifies core state data for a reality.
 * 5. addRealityProperty(uint256 realityID, string key, bytes value): Adds a named property to a reality.
 * 6. updateRealityProperty(uint256 realityID, string key, bytes value): Updates an existing reality property.
 * 7. removeRealityProperty(uint256 realityID, string key): Deletes a reality property.
 * 8. trackRealityValue(uint256 realityID, uint256 amount): Adds to a reality's tracked value.
 * 9. addContributor(uint256 realityID, address contributor): Marks an address as interacting with a reality.
 * 10. transferRealityOwnership(uint256 realityID, address newOwner): Changes a reality's owner.
 * 11. setMergeLogicHint(uint256 realityID, bytes hintData): Stores data guiding potential merges involving this reality.
 * 12. setCollapseOutcomeHint(uint256 realityID, bytes hintData): Stores data suggesting the outcome of collapsing this reality.
 * 13. proposeAndExecuteMerge(uint256 realityID1, uint256 realityID2, bytes mergeLogicData): Attempts to merge two realities based on hints and external logic parameters.
 * 14. initiateCollapseProcess(uint256 realityID): Flags a reality for collapse.
 * 15. finalizeCollapseOutcome(uint256 realityID, bytes executionParameters): Finalizes a collapsed reality using hint/parameters.
 * 16. abandonReality(uint256 realityID): Marks a reality as abandoned.
 * 17. getRealityDetails(uint256 realityID): Retrieves Reality struct data (excluding mappings/arrays).
 * 18. getRealityStatus(uint256 realityID): Gets the current status enum of a reality.
 * 19. isRealityActive(uint256 realityID): Checks if a reality's status is Active.
 * 20. getParentReality(uint256 realityID): Gets the parent ID of a reality.
 * 21. listChildRealities(uint256 parentID): Gets the list of direct children IDs.
 * 22. getRealityProperty(uint256 realityID, string key): Gets the value of a specific property key.
 * 23. getRealityPropertyKeys(uint256 realityID): Gets the list of all property keys for a reality.
 * 24. getTrackedRealityValue(uint256 realityID): Gets the current tracked value.
 * 25. getContributors(uint256 realityID): Gets the list of unique contributors.
 * 26. getTotalRealitiesCount(): Gets the total count of realities created.
 * 27. getOwnedRealitiesCount(address owner): Gets the count of realities owned by an address.
 * 28. checkAncestry(uint256 childID, uint256 potentialAncestorID): Verifies if one reality is an ancestor of another.
 * 29. getRealityCreationBlock(uint256 realityID): Gets the block number the reality was created.
 * 30. getLastInteractionBlock(uint256 realityID): Gets the block number of the last state/property interaction.
 * 31. setMetadataURI(uint256 realityID, string uri): Sets a URI for off-chain metadata.
 */
contract QuantumLeapFactory {

    // 1. State Definitions
    enum RealityStatus { NonExistent, Active, Merged, Collapsed, Abandoned }

    struct Reality {
        uint256 id;
        uint256 parentID; // 0 for the prime reality
        address owner;
        uint256 originBlock;
        uint256 lastInteractionBlock;
        RealityStatus status;
        bytes stateData; // Core state data for this reality instance
        mapping(string => bytes) properties; // Dynamic properties
        string[] propertyKeys; // To retrieve keys for the properties mapping
        mapping(address => bool) contributors; // Addresses that have interacted
        address[] contributorList; // To retrieve contributors
        uint256 trackedValue; // A simple numerical value associated with this reality
        bytes mergeLogicHint; // Data hinting how this reality should be merged
        bytes collapseOutcomeHint; // Data hinting the outcome if this reality is collapsed
        string metadataURI; // Optional URI for off-chain data
    }

    // 2. Storage Variables
    uint256 private totalRealitiesCount;
    mapping(uint256 => Reality) private idToReality;
    mapping(uint256 => uint256[]) private childRealities; // parentID => list of child IDs
    mapping(address => mapping(uint256 => bool)) private ownerRealities; // owner => realityID => exists
    mapping(address => uint256) private ownerRealityCount; // owner => count

    address public immutable owner; // Contract deployer

    // 3. Events
    event PrimeRealityCreated(uint256 realityID, address indexed creator, bytes initialData);
    event RealityBranched(uint256 indexed newRealityID, uint256 indexed parentID, address indexed creator, bytes branchData);
    event RealityStateUpdated(uint256 indexed realityID, address indexed updater, bytes newState);
    event RealityPropertyChanged(uint256 indexed realityID, string indexed key, address indexed updater, bytes newValue);
    event RealityValueTracked(uint256 indexed realityID, address indexed sender, uint256 amount, uint256 totalValue);
    event ContributorAdded(uint256 indexed realityID, address indexed contributor);
    event RealityOwnershipTransferred(uint256 indexed realityID, address indexed oldOwner, address indexed newOwner);
    event MergeLogicHintSet(uint256 indexed realityID, address indexed setter, bytes hintData);
    event CollapseOutcomeHintSet(uint256 indexed realityID, address indexed setter, bytes hintData);
    event RealitiesMerged(uint256 indexed targetRealityID, uint256 indexed sourceRealityID, address indexed merger, bytes mergeLogicData);
    event CollapseProcessInitiated(uint256 indexed realityID, address indexed initiator);
    event CollapseOutcomeFinalized(uint256 indexed realityID, address indexed finalizer, bytes executionParameters);
    event RealityAbandoned(uint256 indexed realityID, address indexed abandoner);
    event MetadataURISet(uint256 indexed realityID, address indexed setter, string uri);

    // 4. Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "QLE: Not contract owner");
        _;
    }

    modifier onlyRealityOwner(uint256 realityID) {
        require(idToReality[realityID].owner == msg.sender, "QLE: Not reality owner");
        _;
    }

    modifier whenRealityExists(uint256 realityID) {
        require(idToReality[realityID].status != RealityStatus.NonExistent, "QLE: Reality does not exist");
        _;
    }

    modifier whenRealityActive(uint256 realityID) {
        require(idToReality[realityID].status == RealityStatus.Active, "QLE: Reality is not active");
        _;
    }

    modifier whenRealityStatusIs(uint256 realityID, RealityStatus status) {
         require(idToReality[realityID].status == status, "QLE: Reality status mismatch");
        _;
    }

    // 5. Constructor
    constructor() {
        owner = msg.sender;
    }

    // 6. Core Factory Functions
    /**
     * @notice Creates the initial 'prime' reality.
     * @param initialData Data to initialize the prime reality's state.
     */
    function createPrimeReality(bytes memory initialData) external whenRealityStatusIs(1, RealityStatus.NonExistent) {
        totalRealitiesCount = 1;
        uint256 newID = 1; // Prime reality is always ID 1

        Reality storage newReality = idToReality[newID];
        newReality.id = newID;
        newReality.parentID = 0;
        newReality.owner = msg.sender;
        newReality.originBlock = block.number;
        newReality.lastInteractionBlock = block.number;
        newReality.status = RealityStatus.Active;
        newReality.stateData = initialData;
        // Properties, contributors, trackedValue start empty/zero

        ownerRealities[msg.sender][newID] = true;
        ownerRealityCount[msg.sender]++;

        emit PrimeRealityCreated(newID, msg.sender, initialData);
    }

    // 7. Reality Lifecycle Functions

    /**
     * @notice Creates a new reality instance branched from an existing one.
     * State data and hints are copied. Properties, contributors, and value start fresh.
     * @param parentID The ID of the reality to branch from.
     * @param branchData Arbitrary data associated with the branching event.
     * @return The ID of the newly created reality.
     */
    function branchReality(uint256 parentID, bytes memory branchData)
        external
        whenRealityActive(parentID)
        returns (uint256 newRealityID)
    {
        totalRealitiesCount++;
        newRealityID = totalRealitiesCount;

        Reality storage parentReality = idToReality[parentID];
        Reality storage newReality = idToReality[newRealityID];

        newReality.id = newRealityID;
        newReality.parentID = parentID;
        newReality.owner = msg.sender; // Owner of the new branch is the caller
        newReality.originBlock = block.number;
        newReality.lastInteractionBlock = block.number;
        newReality.status = RealityStatus.Active;
        newReality.stateData = parentReality.stateData; // Copy state data
        newReality.mergeLogicHint = parentReality.mergeLogicHint; // Copy hints
        newReality.collapseOutcomeHint = parentReality.collapseOutcomeHint; // Copy hints
        // Properties, contributors, trackedValue start fresh

        childRealities[parentID].push(newRealityID);
        ownerRealities[msg.sender][newRealityID] = true;
        ownerRealityCount[msg.sender]++;

        emit RealityBranched(newRealityID, parentID, msg.sender, branchData);
    }

    /**
     * @notice Attempts to execute a merge between two realities.
     * This function provides a *template* for merging. Real-world use
     * would require specific logic based on `mergeLogicData`.
     * Example logic implemented here: Copy state/properties/value from `sourceRealityID`
     * to `targetRealityID`, then mark `sourceRealityID` as Merged.
     * @param targetRealityID The reality to merge into.
     * @param sourceRealityID The reality whose state/properties are copied from.
     * @param mergeLogicData Arbitrary data guiding the merge logic (e.g., selection criteria).
     *   For this example, mergeLogicData is ignored, and we just use the IDs.
     */
    function proposeAndExecuteMerge(uint256 targetRealityID, uint256 sourceRealityID, bytes memory mergeLogicData)
        external
        whenRealityActive(targetRealityID)
        whenRealityActive(sourceRealityID)
        // Add more specific permission checks as needed, e.g., only owner of target/source
    {
        require(targetRealityID != sourceRealityID, "QLE: Cannot merge reality with itself");

        Reality storage targetReality = idToReality[targetRealityID];
        Reality storage sourceReality = idToReality[sourceRealityID];

        // --- Example Merge Logic (Placeholder) ---
        // In a real application, this logic would interpret mergeLogicData
        // and/or the realities' internal states/hints to determine the outcome.
        // Here, we implement a simple "copy from source to target" logic.

        targetReality.stateData = sourceReality.stateData;
        targetReality.trackedValue += sourceReality.trackedValue; // Example: combine values
        targetReality.lastInteractionBlock = block.number;

        // Copy properties - this is gas intensive for many properties
        // A more complex merge logic might be needed here.
        // For this example, we just clear target properties and copy source.
        // This isn't a true merge but a simple overwrite.
        // A real merge might involve conflict resolution based on keys/values.
        delete targetReality.properties; // Clear existing properties in target
        delete targetReality.propertyKeys;
        for(uint i = 0; i < sourceReality.propertyKeys.length; i++) {
             string memory key = sourceReality.propertyKeys[i];
             targetReality.properties[key] = sourceReality.properties[key];
             targetReality.propertyKeys.push(key);
        }
        // --- End Example Merge Logic ---

        sourceReality.status = RealityStatus.Merged; // Mark the source as merged
        // Optionally transfer ownership of source reality ID if needed, or nullify owner

        emit RealitiesMerged(targetRealityID, sourceRealityID, msg.sender, mergeLogicData);
        emit RealityStateUpdated(targetRealityID, msg.sender, targetReality.stateData); // Signal target state changed
         // Potentially emit PropertyChanged events for all copied properties
    }

     /**
     * @notice Marks a reality as being in the process of collapsing.
     * This typically precedes `finalizeCollapseOutcome`.
     * @param realityID The ID of the reality to collapse.
     */
    function initiateCollapseProcess(uint256 realityID)
        external
        onlyRealityOwner(realityID)
        whenRealityActive(realityID)
    {
        idToReality[realityID].status = RealityStatus.Collapsed;
        idToReality[realityID].lastInteractionBlock = block.number;
        emit CollapseProcessInitiated(realityID, msg.sender);
    }

    /**
     * @notice Finalizes the outcome of a collapsed reality.
     * The logic for the outcome depends on the `collapseOutcomeHint` and `executionParameters`.
     * This function provides a *template* for finalization. Real-world use
     * would require specific logic based on these parameters.
     * Example logic: Interpret `collapseOutcomeHint` as an address and emit an event declaring it a winner.
     * @param realityID The ID of the reality to finalize.
     * @param executionParameters Arbitrary data guiding the finalization logic.
     */
    function finalizeCollapseOutcome(uint256 realityID, bytes memory executionParameters)
        external
        onlyRealityOwner(realityID)
        whenRealityStatusIs(realityID, RealityStatus.Collapsed)
    {
        Reality storage reality = idToReality[realityID];

        // --- Example Collapse Logic (Placeholder) ---
        // This logic interprets reality.collapseOutcomeHint and executionParameters
        // to perform a final action or determine a final state/winner.
        // Here, we assume collapseOutcomeHint is a 20-byte address.
        address winner = address(0);
        if (reality.collapseOutcomeHint.length == 20) {
            assembly {
                winner := mload(add(reality.collapseOutcomeHint, 32))
            }
        }

        // Emit event signaling the outcome
        // More complex outcomes might involve triggering transfers, state changes elsewhere, etc.
        // The executionParameters could provide context for this.
        emit CollapseOutcomeFinalized(realityID, msg.sender, executionParameters);

        // Optionally transition status again, e.g., to Completed or just leave as Collapsed
        // reality.status = RealityStatus.Completed; // Need to add Completed status? Let's stick to current enum.
        reality.lastInteractionBlock = block.number;
         // Do NOT change status again here unless a new final status is added.
    }

    /**
     * @notice Marks a reality as abandoned. Cannot be reactivated or used for branching/merging.
     * @param realityID The ID of the reality to abandon.
     */
    function abandonReality(uint256 realityID)
        external
        onlyRealityOwner(realityID)
        whenRealityActive(realityID)
    {
        idToReality[realityID].status = RealityStatus.Abandoned;
        idToReality[realityID].lastInteractionBlock = block.number;
         // Optional: remove from ownerRealities mapping - gas intensive
        // delete ownerRealities[msg.sender][realityID];
        // ownerRealityCount[msg.sender]--;

        emit RealityAbandoned(realityID, msg.sender);
    }


    // 8. Reality Interaction Functions

    /**
     * @notice Updates the core state data of an active reality.
     * @param realityID The ID of the reality.
     * @param newState The new bytes data for the state.
     */
    function updateRealityStateData(uint256 realityID, bytes memory newState)
        external
        onlyRealityOwner(realityID)
        whenRealityActive(realityID)
    {
        idToReality[realityID].stateData = newState;
        idToReality[realityID].lastInteractionBlock = block.number;
        emit RealityStateUpdated(realityID, msg.sender, newState);
    }

    /**
     * @notice Adds a new dynamic property to an active reality. Fails if key exists.
     * @param realityID The ID of the reality.
     * @param key The string key for the property.
     * @param value The bytes value for the property.
     */
    function addRealityProperty(uint256 realityID, string memory key, bytes memory value)
        external
        onlyRealityOwner(realityID)
        whenRealityActive(realityID)
    {
        // Check if key already exists (iterating keys is necessary due to mapping nature)
        bool keyExists = false;
        string[] storage keys = idToReality[realityID].propertyKeys;
        for(uint i = 0; i < keys.length; i++) {
            if (keccak256(bytes(keys[i])) == keccak256(bytes(key))) {
                keyExists = true;
                break;
            }
        }
        require(!keyExists, "QLE: Property key already exists");

        idToReality[realityID].properties[key] = value;
        idToReality[realityID].propertyKeys.push(key);
        idToReality[realityID].lastInteractionBlock = block.number;
        emit RealityPropertyChanged(realityID, key, msg.sender, value);
    }

    /**
     * @notice Updates an existing dynamic property of an active reality. Fails if key does not exist.
     * @param realityID The ID of the reality.
     * @param key The string key for the property.
     * @param value The new bytes value for the property.
     */
    function updateRealityProperty(uint256 realityID, string memory key, bytes memory value)
        external
        onlyRealityOwner(realityID)
        whenRealityActive(realityID)
    {
         // Check if key exists
        bool keyExists = false;
         string[] storage keys = idToReality[realityID].propertyKeys;
        for(uint i = 0; i < keys.length; i++) {
            if (keccak256(bytes(keys[i])) == keccak256(bytes(key))) {
                keyExists = true;
                break;
            }
        }
        require(keyExists, "QLE: Property key does not exist");

        idToReality[realityID].properties[key] = value;
        idToReality[realityID].lastInteractionBlock = block.number;
        emit RealityPropertyChanged(realityID, key, msg.sender, value);
    }

     /**
     * @notice Removes a dynamic property from an active reality.
     * @param realityID The ID of the reality.
     * @param key The string key for the property.
     */
    function removeRealityProperty(uint256 realityID, string memory key)
        external
        onlyRealityOwner(realityID)
        whenRealityActive(realityID)
    {
        Reality storage reality = idToReality[realityID];

        // Check if key exists and find its index
        int256 keyIndex = -1;
        for(uint i = 0; i < reality.propertyKeys.length; i++) {
            if (keccak256(bytes(reality.propertyKeys[i])) == keccak256(bytes(key))) {
                keyIndex = int256(i);
                break;
            }
        }
        require(keyIndex != -1, "QLE: Property key does not exist");

        delete reality.properties[key];

        // Remove key from propertyKeys array (efficiently swap with last and pop)
        uint lastIndex = reality.propertyKeys.length - 1;
        if (uint(keyIndex) != lastIndex) {
            reality.propertyKeys[uint(keyIndex)] = reality.propertyKeys[lastIndex];
        }
        reality.propertyKeys.pop();

        reality.lastInteractionBlock = block.number;
        // Note: No specific event for removal value, just PropertyChanged with empty value or specific Removed event?
        // Let's emit PropertyChanged with a zero-length bytes value as convention for removal.
         emit RealityPropertyChanged(realityID, key, msg.sender, bytes("")); // Convention: empty bytes indicates removal
    }


     /**
     * @notice Adds a numerical value to the tracked value of an active reality.
     * @param realityID The ID of the reality.
     * @param amount The amount to add.
     */
    function trackRealityValue(uint256 realityID, uint256 amount)
        external
        whenRealityActive(realityID)
    {
        // Anyone can contribute value? Or only owner? Depends on desired logic.
        // Let's allow anyone to add value for flexibility.
        idToReality[realityID].trackedValue += amount;
        idToReality[realityID].lastInteractionBlock = block.number;
        // Add sender as contributor implicitly? Let's do it explicitly via addContributor.
        emit RealityValueTracked(realityID, msg.sender, amount, idToReality[realityID].trackedValue);
    }

    /**
     * @notice Records an address as having contributed to or interacted with a reality.
     * @param realityID The ID of the reality.
     * @param contributor The address to record.
     */
    function addContributor(uint256 realityID, address contributor)
        external
        whenRealityActive(realityID)
    {
        Reality storage reality = idToReality[realityID];
        if (!reality.contributors[contributor]) {
            reality.contributors[contributor] = true;
            reality.contributorList.push(contributor); // Maintain a list for retrieval
            reality.lastInteractionBlock = block.number;
            emit ContributorAdded(realityID, contributor);
        }
    }


    /**
     * @notice Transfers ownership of a reality to a new address.
     * @param realityID The ID of the reality.
     * @param newOwner The address of the new owner.
     */
    function transferRealityOwnership(uint256 realityID, address newOwner)
        external
        onlyRealityOwner(realityID)
        whenRealityExists(realityID) // Can transfer ownership even if not active? Let's allow.
    {
        address oldOwner = msg.sender;
        Reality storage reality = idToReality[realityID];

        // Update owner mappings (potentially gas intensive if many realities)
        delete ownerRealities[oldOwner][realityID];
        ownerRealityCount[oldOwner]--;
        ownerRealities[newOwner][realityID] = true;
        ownerRealityCount[newOwner]++;

        reality.owner = newOwner;
        reality.lastInteractionBlock = block.number;

        emit RealityOwnershipTransferred(realityID, oldOwner, newOwner);
    }

    // 10. Rule/Logic Hinting Functions

    /**
     * @notice Sets arbitrary data that can be interpreted by off-chain or future on-chain
     * logic to guide how this reality should be merged with others.
     * @param realityID The ID of the reality.
     * @param hintData The bytes data containing the merge logic hint.
     */
    function setMergeLogicHint(uint256 realityID, bytes memory hintData)
        external
        onlyRealityOwner(realityID)
        whenRealityExists(realityID) // Can set hint even if not active? Yes, for planning.
    {
        idToReality[realityID].mergeLogicHint = hintData;
        idToReality[realityID].lastInteractionBlock = block.number; // Interaction counts even for hints
        emit MergeLogicHintSet(realityID, msg.sender, hintData);
    }

    /**
     * @notice Sets arbitrary data that can be interpreted to determine the outcome
     * when this reality is finalized after being collapsed.
     * @param realityID The ID of the reality.
     * @param hintData The bytes data containing the collapse outcome hint.
     */
    function setCollapseOutcomeHint(uint256 realityID, bytes memory hintData)
        external
        onlyRealityOwner(realityID)
        whenRealityExists(realityID) // Can set hint even if not active? Yes, for planning.
    {
        idToReality[realityID].collapseOutcomeHint = hintData;
        idToReality[realityID].lastInteractionBlock = block.number;
        emit CollapseOutcomeHintSet(realityID, msg.sender, hintData);
    }

    /**
     * @notice Sets an optional URI pointing to off-chain metadata about this reality.
     * @param realityID The ID of the reality.
     * @param uri The URI string.
     */
    function setMetadataURI(uint256 realityID, string memory uri)
        external
        onlyRealityOwner(realityID)
        whenRealityExists(realityID)
    {
        idToReality[realityID].metadataURI = uri;
        idToReality[realityID].lastInteractionBlock = block.number;
        emit MetadataURISet(realityID, msg.sender, uri);
    }


    // 9. Query Functions (Read-only)

    /**
     * @notice Gets basic details of a reality (excluding mapping/array data).
     * @param realityID The ID of the reality.
     * @return tuple containing (id, parentID, owner, originBlock, lastInteractionBlock, status, stateData, trackedValue, mergeLogicHint, collapseOutcomeHint, metadataURI).
     */
    function getRealityDetails(uint256 realityID)
        external
        view
        whenRealityExists(realityID)
        returns (
            uint256 id,
            uint256 parentID,
            address owner,
            uint256 originBlock,
            uint256 lastInteractionBlock,
            RealityStatus status,
            bytes memory stateData,
            uint256 trackedValue,
            bytes memory mergeLogicHint,
            bytes memory collapseOutcomeHint,
            string memory metadataURI
        )
    {
        Reality storage reality = idToReality[realityID];
        return (
            reality.id,
            reality.parentID,
            reality.owner,
            reality.originBlock,
            reality.lastInteractionBlock,
            reality.status,
            reality.stateData,
            reality.trackedValue,
            reality.mergeLogicHint,
            reality.collapseOutcomeHint,
            reality.metadataURI
        );
    }

    /**
     * @notice Gets the current status of a reality.
     * @param realityID The ID of the reality.
     * @return The RealityStatus enum value.
     */
    function getRealityStatus(uint256 realityID)
        external
        view
        whenRealityExists(realityID)
        returns (RealityStatus)
    {
        return idToReality[realityID].status;
    }

    /**
     * @notice Checks if a reality's status is Active.
     * @param realityID The ID of the reality.
     * @return True if status is Active, false otherwise.
     */
    function isRealityActive(uint256 realityID)
        external
        view
        returns (bool)
    {
         return idToReality[realityID].status == RealityStatus.Active;
    }


    /**
     * @notice Gets the parent reality ID. Returns 0 for the prime reality.
     * @param realityID The ID of the reality.
     * @return The parent reality ID.
     */
    function getParentReality(uint256 realityID)
        external
        view
        whenRealityExists(realityID)
        returns (uint256)
    {
        return idToReality[realityID].parentID;
    }

    /**
     * @notice Lists the direct child reality IDs of a given parent reality.
     * @param parentID The ID of the parent reality.
     * @return An array of child reality IDs.
     */
    function listChildRealities(uint256 parentID)
        external
        view
        whenRealityExists(parentID)
        returns (uint256[] memory)
    {
        return childRealities[parentID];
    }

    /**
     * @notice Gets the value of a specific dynamic property for a reality.
     * @param realityID The ID of the reality.
     * @param key The string key for the property.
     * @return The bytes value of the property. Returns empty bytes if key does not exist or reality doesn't exist.
     */
    function getRealityProperty(uint256 realityID, string memory key)
        external
        view
        returns (bytes memory)
    {
        if (idToReality[realityID].status == RealityStatus.NonExistent) {
            return bytes(""); // Return empty bytes for non-existent reality
        }
        // Note: Cannot check existence of mapping key directly, rely on client checking existence via propertyKeys
        return idToReality[realityID].properties[key];
    }

    /**
     * @notice Lists all property keys for a reality.
     * @param realityID The ID of the reality.
     * @return An array of property keys.
     */
    function getRealityPropertyKeys(uint256 realityID)
        external
        view
        whenRealityExists(realityID)
        returns (string[] memory)
    {
        return idToReality[realityID].propertyKeys;
    }


    /**
     * @notice Gets the current tracked value for a reality.
     * @param realityID The ID of the reality.
     * @return The tracked uint256 value. Returns 0 for non-existent realities.
     */
    function getTrackedRealityValue(uint256 realityID)
        external
        view
        returns (uint256)
    {
        if (idToReality[realityID].status == RealityStatus.NonExistent) {
            return 0;
        }
        return idToReality[realityID].trackedValue;
    }

     /**
     * @notice Gets the list of unique addresses that have contributed to or interacted with a reality.
     * @param realityID The ID of the reality.
     * @return An array of contributor addresses.
     */
    function getContributors(uint256 realityID)
        external
        view
        whenRealityExists(realityID)
        returns (address[] memory)
    {
        return idToReality[realityID].contributorList;
    }

    /**
     * @notice Gets the total number of realities ever created by the factory.
     * @return The total count.
     */
    function getTotalRealitiesCount() external view returns (uint256) {
        return totalRealitiesCount;
    }

    /**
     * @notice Gets the number of realities owned by a specific address.
     * @param owner The address to check.
     * @return The count of realities owned by the address.
     */
    function getOwnedRealitiesCount(address owner) external view returns (uint256) {
        return ownerRealityCount[owner];
    }

     /**
     * @notice Checks if a potential ancestor reality is indeed in the ancestry path of a child reality.
     * Note: This is a potentially gas-intensive operation for deep ancestry trees.
     * @param childID The ID of the potential child reality.
     * @param potentialAncestorID The ID of the reality to check as an ancestor.
     * @return True if potentialAncestorID is an ancestor of childID (including the child itself if IDs match and exists), false otherwise.
     */
    function checkAncestry(uint256 childID, uint256 potentialAncestorID) external view returns (bool) {
        if (idToReality[childID].status == RealityStatus.NonExistent || idToReality[potentialAncestorID].status == RealityStatus.NonExistent) {
            return false;
        }

        uint256 currentID = childID;
        // Iterate up the parent chain
        while (currentID != 0) {
            if (currentID == potentialAncestorID) {
                return true;
            }
            // Prevent infinite loops in case of data corruption (though shouldn't happen with this logic)
            // Limit search depth if trees could be extremely deep - omitted for simplicity here.
            currentID = idToReality[currentID].parentID;
        }

        return false; // Reached the root (ID 0) without finding the ancestor
    }

    /**
     * @notice Gets the block number when the reality was originally created.
     * @param realityID The ID of the reality.
     * @return The creation block number. Returns 0 for non-existent realities.
     */
    function getRealityCreationBlock(uint256 realityID) external view returns (uint256) {
         if (idToReality[realityID].status == RealityStatus.NonExistent) {
            return 0;
        }
        return idToReality[realityID].originBlock;
    }

    /**
     * @notice Gets the block number of the last interaction (state, property, value update, ownership transfer, hint set, status change).
     * @param realityID The ID of the reality.
     * @return The last interaction block number. Returns 0 for non-existent realities (prime reality is block 0 if created at deployment, otherwise block number).
     */
    function getLastInteractionBlock(uint256 realityID) external view returns (uint256) {
         if (idToReality[realityID].status == RealityStatus.NonExistent) {
            return 0;
        }
        return idToReality[realityID].lastInteractionBlock;
    }
}
```