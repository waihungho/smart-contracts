Okay, let's create a smart contract that simulates a system of interconnected "dimensions" with varying states, stabilities, and associated data. Users can interact with these dimensions by "exploring" them, "contributing stability," and storing "data fragments." The dimensions decay over time and have a chance of experiencing "anomalies" based on their state.

This concept is advanced due to:
*   **Dynamic State:** Dimensions decay over time, influencing costs and anomaly risks.
*   **Structured State:** Each dimension has its own complex state (stability, properties, user data, contributions).
*   **Inter-dimensional Links:** Dimensions can be linked, representing relationships.
*   **Triggered Mechanics:** Decay and anomaly checks are triggered externally, potentially incentivizing users to maintain the system.
*   **Internal Logic:** Calculation of costs, anomaly chances, and decay involves non-trivial logic.
*   **Data Storage:** Storing arbitrary key-value data associated with dimensions.

It's creative as it models a conceptual system rather than a typical financial or asset contract. It's trendy in its nod towards complex, evolving decentralized worlds or simulations, fitting into potential DeSci (Decentralized Science) or advanced gaming paradigms. It avoids duplicating standard tokens, vaults, or governance structures directly.

---

## QuantumTunnel Smart Contract

**Concept:** A system managing interconnected "dimensions" with dynamic stability, properties, and associated data. Users interact to explore, stabilize, and add data fragments. Dimensions decay over time and may experience anomalies.

**Outline:**

1.  **State Variables:** Stores contract owner, global parameters, dimension data, user interactions, links between dimensions.
2.  **Structs:** Defines the structure of a `Dimension`.
3.  **Events:** Notifies off-chain listeners about key state changes (Dimension creation, exploration, stability change, anomalies, data updates, linking).
4.  **Errors:** Custom errors for clearer failure reasons.
5.  **Modifiers:** `onlyOwner` for restricted functions.
6.  **Constructor:** Initializes the contract and creates the genesis dimension.
7.  **Admin Functions:** Set global parameters, manage core settings.
8.  **Dimension Management:** Create, update, and view dimensions.
9.  **User Interaction:** Explore dimensions, contribute stability, store and retrieve data.
10. **System Mechanics:** Trigger stability decay, check for anomalies, manage inter-dimension links.
11. **View Functions:** Read contract state and dimension details.

**Function Summary:**

1.  `constructor()`: Initializes contract with owner and calls `initializeGenesisDimension`.
2.  `initializeGenesisDimension()`: Creates the very first dimension (can only be called once by owner).
3.  `setExplorationBaseCost(uint256 newCost)`: Sets the base ETH cost for exploring any dimension (Owner).
4.  `setStabilityDecayRate(uint256 newRate)`: Sets the rate at which dimension stability decays over time (Owner).
5.  `createDimension(uint256 initialStability, uint256 initialAnomalyRisk, uint256 initialInteractionFee)`: Creates a new dimension, requiring an ETH payment calculated based on desired initial stability.
6.  `getDimensionDetails(uint256 dimensionId)`: Retrieves core properties of a specific dimension.
7.  `listDimensionIds()`: Returns an array of all existing dimension IDs.
8.  `exploreDimension(uint256 dimensionId)`: Allows a user to explore a dimension, paying the current exploration cost. Increases interaction count.
9.  `contributeStability(uint256 dimensionId)`: Allows a user to send ETH to increase a dimension's stability. Tracks user contribution.
10. `getUserDimensionContribution(uint256 dimensionId, address explorer)`: Retrieves the total ETH contributed by a specific user to a specific dimension.
11. `storeDimensionData(uint256 dimensionId, bytes32 key, bytes calldata data)`: Allows a user to store arbitrary data associated with a dimension under a specific key (requires small ETH payment).
12. `retrieveDimensionData(uint256 dimensionId, bytes32 key)`: Retrieves stored data for a given dimension and key.
13. `decaySingleDimensionStability(uint256 dimensionId)`: Anyone can call this to trigger stability decay for a specific dimension based on time elapsed since last decay.
14. `triggerRandomAnomalyCheck()`: Anyone can call this to check a random dimension for a potential anomaly based on its current state and risk parameters.
15. `getDimensionInteractionCount(uint256 dimensionId)`: Returns the total number of times a dimension has been explored.
16. `getDimensionStability(uint256 dimensionId)`: Returns the current stability level of a dimension.
17. `calculateCurrentExplorationCost(uint256 dimensionId)`: Calculates the current ETH cost to explore a dimension, potentially influenced by its stability.
18. `linkDimensions(uint256 dimension1Id, uint256 dimension2Id)`: Links two dimensions together (Owner or requires specific conditions met, like stability thresholds).
19. `getLinkedDimensions(uint256 dimensionId)`: Returns an array of dimensions linked to the given dimension.
20. `requestDimensionAnalysis(uint256 dimensionId)`: Allows a user to pay ETH to request an "analysis" of a dimension, potentially triggering off-chain processing or internal state flags (in this example, just records the request and pays the owner).
21. `setDimensionInteractionFee(uint256 dimensionId, uint256 newFee)`: Sets a specific ETH fee required *in addition* to the exploration cost for interacting with a dimension (Owner).
22. `getDimensionInteractionFee(uint256 dimensionId)`: Returns the current interaction fee for a dimension.
23. `withdrawFees()`: Allows the owner to withdraw collected fees from analysis requests and specific dimension interaction fees.
24. `getAnomalyRiskDetails(uint256 dimensionId)`: Returns the anomaly risk parameter for a dimension.
25. `getTotalStability()`: Calculates and returns the sum of stability across all dimensions (potentially gas-intensive if many dimensions).
26. `getDimensionsByStabilityThreshold(uint256 minStability)`: Returns a list of dimension IDs with stability greater than or equal to the threshold (potentially gas-intensive).
27. `addDimensionTag(uint256 dimensionId, string calldata tag)`: Adds a descriptive tag to a dimension (Owner or conditional).
28. `getDimensionTags(uint256 dimensionId)`: Returns the list of tags associated with a dimension.
29. `removeDimensionData(uint256 dimensionId, bytes32 key)`: Allows the original storer of data to remove it (requires tracking storer, or simply allows anyone to remove? Let's allow original storer). *Correction:* Tracking storer per data key adds significant complexity. Let's simplify: Owner can remove, or maybe anyone if data is 'expired'? For this example, let's make it an Owner function or require a proof of storage ownership (beyond scope here). Revert to a simple `removeDimensionDataEntry` by key, maybe only callable by owner or under specific conditions. Let's make it owner-only to keep it simple for the function count.
30. `getExplorerDimensions(address explorer)`: Returns a list of dimension IDs that a specific explorer has interacted with.
31. `removeDimensionTag(uint256 dimensionId, string calldata tag)`: Removes a specific tag from a dimension (Owner or conditional).
32. `getDimensionCreationTimestamp(uint256 dimensionId)`: Returns the timestamp when a dimension was created.
33. `updateDimensionAnomalyRisk(uint256 dimensionId, uint256 newRisk)`: Updates the anomaly risk parameter for a dimension (Owner).
34. `updateDimensionStabilityThreshold(uint256 dimensionId, uint256 newThreshold)`: Updates the stability threshold parameter for a dimension (Owner).

*Self-Correction during summary:* The list has 34 functions, well over 20. The initial plan had 30, and adding `removeDimensionTag`, `getDimensionCreationTimestamp`, `updateDimensionAnomalyRisk`, `updateDimensionStabilityThreshold` brings it to 34. All seem distinct and contribute to the contract's complexity and features. Removing data by key needs a slight refinement; owner-only is simpler. Getting explorer dimensions needs tracking.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumTunnel
 * @notice A smart contract simulating a system of dynamic dimensions with stability, decay, anomalies, and data storage.
 * Users can explore, contribute stability, and store data within dimensions. Dimensions decay over time and can be linked.
 */

// Outline:
// 1. State Variables: Global parameters, dimension data, user interactions, links.
// 2. Structs: Dimension definition.
// 3. Events: Notifications for key actions.
// 4. Errors: Custom error types.
// 5. Modifiers: onlyOwner.
// 6. Constructor: Initializes contract and genesis dimension.
// 7. Admin Functions: Set global params, manage core settings.
// 8. Dimension Management: Create, update, view dimensions.
// 9. User Interaction: Explore, contribute stability, store/retrieve data.
// 10. System Mechanics: Trigger decay, check anomalies, manage links.
// 11. View Functions: Read state.

// Function Summary:
// 1. constructor(): Initializes contract, owner, and genesis dimension.
// 2. initializeGenesisDimension(): Creates the first dimension (Owner, callable once).
// 3. setExplorationBaseCost(uint256 newCost): Sets the base ETH cost for exploration (Owner).
// 4. setStabilityDecayRate(uint256 newRate): Sets rate for stability decay (Owner).
// 5. createDimension(uint256 initialStability, uint256 initialAnomalyRisk, uint256 initialInteractionFee): Creates a new dimension requiring ETH payment.
// 6. getDimensionDetails(uint256 dimensionId): Gets core dimension properties.
// 7. listDimensionIds(): Gets all existing dimension IDs.
// 8. exploreDimension(uint256 dimensionId): User explores a dimension, pays cost, increases count.
// 9. contributeStability(uint256 dimensionId): User contributes ETH to stability, tracks contribution.
// 10. getUserDimensionContribution(uint256 dimensionId, address explorer): Gets user's total contribution to a dimension.
// 11. storeDimensionData(uint256 dimensionId, bytes32 key, bytes calldata data): User stores data with cost.
// 12. retrieveDimensionData(uint256 dimensionId, bytes32 key): Retrieves stored data.
// 13. decaySingleDimensionStability(uint256 dimensionId): Triggers time-based stability decay for one dimension.
// 14. triggerRandomAnomalyCheck(): Checks a random dimension for an anomaly.
// 15. getDimensionInteractionCount(uint256 dimensionId): Gets total explorations for a dimension.
// 16. getDimensionStability(uint256 dimensionId): Gets current dimension stability.
// 17. calculateCurrentExplorationCost(uint256 dimensionId): Calculates dynamic exploration cost.
// 18. linkDimensions(uint256 dimension1Id, uint256 dimension2Id): Links two dimensions (Owner).
// 19. getLinkedDimensions(uint256 dimensionId): Gets dimensions linked to a dimension.
// 20. requestDimensionAnalysis(uint256 dimensionId): User pays for analysis request (Owner receives ETH).
// 21. setDimensionInteractionFee(uint256 dimensionId, uint256 newFee): Sets an additional fee per dimension (Owner).
// 22. getDimensionInteractionFee(uint256 dimensionId): Gets dimension's interaction fee.
// 23. withdrawFees(): Owner withdraws collected analysis/interaction fees.
// 24. getAnomalyRiskDetails(uint256 dimensionId): Gets dimension's anomaly risk.
// 25. getTotalStability(): Gets sum of stability across all dimensions (potentially gas heavy).
// 26. getDimensionsByStabilityThreshold(uint256 minStability): Gets IDs of dimensions above a stability threshold (potentially gas heavy).
// 27. addDimensionTag(uint256 dimensionId, string calldata tag): Adds a tag to a dimension (Owner).
// 28. getDimensionTags(uint256 dimensionId): Gets tags for a dimension.
// 29. removeDimensionDataEntry(uint256 dimensionId, bytes32 key): Removes a data entry (Owner).
// 30. getExplorerDimensions(address explorer): Gets dimensions an explorer interacted with.
// 31. removeDimensionTag(uint256 dimensionId, string calldata tag): Removes a tag (Owner).
// 32. getDimensionCreationTimestamp(uint256 dimensionId): Gets creation time.
// 33. updateDimensionAnomalyRisk(uint256 dimensionId, uint256 newRisk): Updates anomaly risk (Owner).
// 34. updateDimensionStabilityThreshold(uint256 dimensionId, uint256 newThreshold): Updates stability threshold (Owner).


contract QuantumTunnel {

    address public owner;

    // Global Parameters
    uint256 public explorationBaseCost = 0.01 ether; // Base cost to explore
    uint256 public stabilityDecayRate = 1e16; // Decay factor per second (0.01%)

    // Dimension Counter
    uint256 public nextDimensionId = 1; // Start from 1

    // Stored Fees
    uint256 private collectedFees = 0;

    // --- Structs ---

    struct Dimension {
        uint256 id;
        uint256 stability; // Higher is more stable
        uint256 explorationCostBase; // Base cost for THIS dimension (can override global)
        uint256 stabilityThreshold; // Stability needed for certain actions/properties
        uint256 anomalyRisk; // Higher is more risky (scaled 0-10000 for 0-100%)
        uint264 lastStabilityDecayTimestamp; // Timestamp of last decay calculation (using uint264 for packing)
        uint256 totalInteractionCount;
        uint256 creationTimestamp;
        uint256 interactionFee; // Additional fee to interact (beyond explorationBaseCost)

        // Mappings for dynamic data per dimension
        mapping(address => uint256) userContributions; // ETH contributed for stability
        mapping(bytes32 => bytes) dataStorage; // Arbitrary key-value data
        mapping(bytes32 => address) dataStorer; // Who stored the data for removal
        mapping(string => bool) tags; // Simple tags
        string[] tagList; // To iterate tags (gas expensive to iterate mappings)

        // Potential for more properties or nested structures...
    }

    // --- State Variables ---

    mapping(uint256 => Dimension) public dimensions;
    uint256[] public dimensionIds; // Keep track of all IDs for iteration (careful with large numbers)

    // Store links between dimensions (undirected graph representation)
    mapping(uint256 => uint256[]) public linkedDimensions;

    // Track dimensions an explorer has interacted with
    mapping(address => mapping(uint256 => bool)) private hasExploredDimension;
    mapping(address => uint256[] ) public explorerDimensions;


    bool private genesisDimensionCreated = false;

    // --- Events ---

    event DimensionCreated(uint256 indexed dimensionId, address indexed creator, uint256 initialStability, uint256 initialAnomalyRisk);
    event DimensionExplored(uint256 indexed dimensionId, address indexed explorer, uint256 costPaid);
    event StabilityContributed(uint256 indexed dimensionId, address indexed contributor, uint256 amount, uint256 newStability);
    event StabilityDecayed(uint256 indexed dimensionId, uint256 oldStability, uint256 newStability, uint256 decayAmount);
    event DataStored(uint256 indexed dimensionId, address indexed storer, bytes32 indexed key, uint256 dataLength);
    event AnomalyDetected(uint256 indexed dimensionId, uint256 anomalyType, string description); // anomalyType could map to specific effects
    event DimensionsLinked(uint256 indexed dimension1Id, uint256 indexed dimension2Id, address indexed linker);
    event AnalysisRequested(uint256 indexed dimensionId, address indexed requester, uint256 costPaid);
    event InteractionFeeUpdated(uint256 indexed dimensionId, uint256 newFee);
    event TagAdded(uint256 indexed dimensionId, string tag);
    event TagRemoved(uint256 indexed dimensionId, string tag);
    event DataEntryRemoved(uint256 indexed dimensionId, bytes32 indexed key);

    // --- Errors ---

    error OnlyOwner();
    error GenesisDimensionAlreadyCreated();
    error DimensionDoesNotExist(uint256 dimensionId);
    error LinkAlreadyExists(uint256 dimension1Id, uint256 dimension2Id);
    error CannotLinkToSelf();
    error NoDataForKey(uint256 dimensionId, bytes32 key);
    error TagDoesNotExist(uint256 dimensionId, string tag);

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier dimensionExists(uint256 _dimensionId) {
        if (dimensions[_dimensionId].id == 0) revert DimensionDoesNotExist(_dimensionId); // id=0 implies struct is not initialized
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        // Genesis dimension is created separately by the owner for explicit control
    }

    // --- Admin Functions ---

    /**
     * @notice Initializes the very first dimension (Genesis Dimension).
     * @dev Can only be called once by the contract owner.
     * @param initialStability Initial stability for the genesis dimension.
     * @param initialAnomalyRisk Initial anomaly risk for the genesis dimension (0-10000).
     * @param initialInteractionFee Initial interaction fee for the genesis dimension.
     */
    function initializeGenesisDimension(
        uint256 initialStability,
        uint256 initialAnomalyRisk,
        uint256 initialInteractionFee
    ) external onlyOwner {
        if (genesisDimensionCreated) revert GenesisDimensionAlreadyCreated();

        _createDimension(
            owner, // Creator is owner for genesis
            initialStability,
            initialAnomalyRisk,
            initialInteractionFee
        );

        genesisDimensionCreated = true;
        emit DimensionCreated(1, owner, initialStability, initialAnomalyRisk);
    }

    /**
     * @notice Sets the base ETH cost for exploring any dimension.
     * @param newCost The new base exploration cost in Wei.
     */
    function setExplorationBaseCost(uint256 newCost) external onlyOwner {
        explorationBaseCost = newCost;
    }

    /**
     * @notice Sets the rate at which dimension stability decays per second.
     * @dev Rate is a fixed point number, 1e18 represents 100%. 1e16 is 0.01%.
     * @param newRate The new decay rate (scaled by 1e18).
     */
    function setStabilityDecayRate(uint256 newRate) external onlyOwner {
        stabilityDecayRate = newRate;
    }

     /**
     * @notice Sets a specific interaction fee for a dimension (Owner).
     * @param dimensionId The ID of the dimension.
     * @param newFee The new interaction fee in Wei.
     */
    function setDimensionInteractionFee(uint256 dimensionId, uint256 newFee)
        external
        onlyOwner
        dimensionExists(dimensionId)
    {
        dimensions[dimensionId].interactionFee = newFee;
        emit InteractionFeeUpdated(dimensionId, newFee);
    }

    /**
     * @notice Updates the anomaly risk parameter for a dimension (Owner).
     * @dev Risk is scaled 0-10000 for 0-100%.
     * @param dimensionId The ID of the dimension.
     * @param newRisk The new anomaly risk value (0-10000).
     */
    function updateDimensionAnomalyRisk(uint256 dimensionId, uint256 newRisk)
        external
        onlyOwner
        dimensionExists(dimensionId)
    {
        dimensions[dimensionId].anomalyRisk = newRisk;
        // Consider adding an event for parameter updates if needed
    }

     /**
     * @notice Updates the stability threshold parameter for a dimension (Owner).
     * @param dimensionId The ID of the dimension.
     * @param newThreshold The new stability threshold value.
     */
    function updateDimensionStabilityThreshold(uint256 dimensionId, uint256 newThreshold)
        external
        onlyOwner
        dimensionExists(dimensionId)
    {
        dimensions[dimensionId].stabilityThreshold = newThreshold;
        // Consider adding an event
    }

    /**
     * @notice Allows the owner to withdraw accumulated fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = collectedFees;
        collectedFees = 0;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
    }


    // --- Dimension Management ---

    /**
     * @notice Creates a new dimension. Requires ETH payment based on initial stability.
     * @param initialStability Desired initial stability for the new dimension.
     * @param initialAnomalyRisk Initial anomaly risk (0-10000).
     * @param initialInteractionFee Initial interaction fee.
     */
    function createDimension(
        uint256 initialStability,
        uint256 initialAnomalyRisk,
        uint256 initialInteractionFee
    ) external payable {
        // Cost to create is proportional to desired initial stability (arbitrary logic)
        uint256 creationCost = initialStability / 1000; // Example: 1 ETH per 1000 stability
        if (msg.value < creationCost)
             revert("Insufficient ETH for dimension creation cost");

        _createDimension(
            msg.sender,
            initialStability,
            initialAnomalyRisk,
            initialInteractionFee
        );

        // Transfer excess ETH back if any
        if (msg.value > creationCost) {
            (bool success, ) = msg.sender.call{value: msg.value - creationCost}("");
            require(success, "Refund failed");
        }

        emit DimensionCreated(nextDimensionId - 1, msg.sender, initialStability, initialAnomalyRisk);
    }

    /**
     * @notice Internal helper function to create a dimension struct and add to state.
     * @dev Increments nextDimensionId.
     * @param creator The address that initiated the creation.
     * @param initialStability Initial stability.
     * @param initialAnomalyRisk Initial anomaly risk.
     * @param initialInteractionFee Initial interaction fee.
     */
    function _createDimension(
        address creator,
        uint256 initialStability,
        uint256 initialAnomalyRisk,
        uint256 initialInteractionFee
    ) internal {
        uint256 dimId = nextDimensionId;
        dimensions[dimId] = Dimension({
            id: dimId,
            stability: initialStability,
            explorationCostBase: explorationBaseCost, // Inherit global base cost
            stabilityThreshold: initialStability / 2, // Example threshold
            anomalyRisk: initialAnomalyRisk,
            lastStabilityDecayTimestamp: uint264(block.timestamp),
            totalInteractionCount: 0,
            creationTimestamp: block.timestamp,
            interactionFee: initialInteractionFee,
            userContributions: mapping(address => uint256), // Initialize internal mappings
            dataStorage: mapping(bytes32 => bytes),
            dataStorer: mapping(bytes32 => address),
            tags: mapping(string => bool),
            tagList: new string[](0) // Initialize empty array
        });
        dimensionIds.push(dimId);
        nextDimensionId++;
    }


    /**
     * @notice Adds a descriptive tag to a dimension.
     * @dev Callable by owner, or could be extended to allow conditional tagging.
     * @param dimensionId The ID of the dimension.
     * @param tag The string tag to add.
     */
    function addDimensionTag(uint256 dimensionId, string calldata tag)
        external
        onlyOwner // Restricted for simplicity; could be conditional
        dimensionExists(dimensionId)
    {
        if (!dimensions[dimensionId].tags[tag]) {
            dimensions[dimensionId].tags[tag] = true;
            dimensions[dimensionId].tagList.push(tag);
            emit TagAdded(dimensionId, tag);
        }
    }

    /**
     * @notice Removes a tag from a dimension.
     * @dev Callable by owner.
     * @param dimensionId The ID of the dimension.
     * @param tag The string tag to remove.
     */
    function removeDimensionTag(uint256 dimensionId, string calldata tag)
        external
        onlyOwner // Restricted for simplicity; could be conditional
        dimensionExists(dimensionId)
    {
        if (!dimensions[dimensionId].tags[tag]) {
            revert TagDoesNotExist(dimensionId, tag);
        }
        delete dimensions[dimensionId].tags[tag];

        // Removing from dynamic array (tagList) is gas-intensive.
        // A common pattern is to swap with last element and pop.
        string[] storage currentTags = dimensions[dimensionId].tagList;
        uint256 indexToRemove = type(uint256).max;
        for (uint256 i = 0; i < currentTags.length; i++) {
            if (keccak256(abi.encodePacked(currentTags[i])) == keccak256(abi.encodePacked(tag))) {
                indexToRemove = i;
                break;
            }
        }

        if (indexToRemove != type(uint256).max) {
            if (indexToRemove < currentTags.length - 1) {
                 currentTags[indexToRemove] = currentTags[currentTags.length - 1];
            }
            currentTags.pop();
        }

        emit TagRemoved(dimensionId, tag);
    }

    /**
     * @notice Removes a stored data entry from a dimension.
     * @dev Callable by owner for simple management. Could be extended to allow original storer only.
     * @param dimensionId The ID of the dimension.
     * @param key The key of the data entry to remove.
     */
     function removeDimensionDataEntry(uint256 dimensionId, bytes32 key)
        external
        onlyOwner // Simplified: only owner can remove
        dimensionExists(dimensionId)
     {
        if(dimensions[dimensionId].dataStorage[key].length == 0 && dimensions[dimensionId].dataStorer[key] == address(0)) {
            revert NoDataForKey(dimensionId, key);
        }

        delete dimensions[dimensionId].dataStorage[key];
        delete dimensions[dimensionId].dataStorer[key]; // Clean up storer record
        emit DataEntryRemoved(dimensionId, key);
     }

    // --- User Interaction ---

    /**
     * @notice Allows a user to explore a dimension. Requires payment of exploration cost + dimension fee.
     * @param dimensionId The ID of the dimension to explore.
     */
    function exploreDimension(uint256 dimensionId)
        external
        payable
        dimensionExists(dimensionId)
    {
        Dimension storage dim = dimensions[dimensionId];
        uint256 totalCost = calculateCurrentExplorationCost(dimensionId) + dim.interactionFee;

        if (msg.value < totalCost) {
            revert("Insufficient ETH to explore dimension");
        }

        // Add to interaction count
        dim.totalInteractionCount++;

        // Track explorer interaction (avoid duplicates in array if needed, but simple append is fine for list)
        if (!hasExploredDimension[msg.sender][dimensionId]) {
             explorerDimensions[msg.sender].push(dimensionId);
             hasExploredDimension[msg.sender][dimensionId] = true;
        }


        // Collect fees
        collectedFees += totalCost; // Owner withdraws later

        // Optional: send small reward to triggerer of last decay/anomaly? Adds complexity.

        emit DimensionExplored(dimensionId, msg.sender, totalCost);

        // Refund excess ETH if any
        if (msg.value > totalCost) {
            (bool success, ) = msg.sender.call{value: msg.value - totalCost}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @notice Allows a user to contribute ETH to a dimension's stability.
     * @param dimensionId The ID of the dimension to contribute to.
     */
    function contributeStability(uint256 dimensionId)
        external
        payable
        dimensionExists(dimensionId)
    {
        if (msg.value == 0) revert("Must contribute non-zero ETH");

        Dimension storage dim = dimensions[dimensionId];
        dim.userContributions[msg.sender] += msg.value;
        dim.stability += msg.value; // 1 ETH contribution adds 1e18 to stability (Wei)

        emit StabilityContributed(dimensionId, msg.sender, msg.value, dim.stability);
    }

    /**
     * @notice Allows a user to store arbitrary bytes data associated with a dimension under a specific key.
     * @dev Requires a small ETH payment (arbitrary fee based on data length).
     * @param dimensionId The ID of the dimension.
     * @param key The bytes32 key for the data entry.
     * @param data The bytes data to store.
     */
    function storeDimensionData(uint256 dimensionId, bytes32 key, bytes calldata data)
        external
        payable
        dimensionExists(dimensionId)
    {
        // Example cost calculation: 1000 Wei per byte of data
        uint256 dataStorageCost = data.length * 1000;
        if (msg.value < dataStorageCost)
            revert("Insufficient ETH for data storage cost");

        Dimension storage dim = dimensions[dimensionId];
        dim.dataStorage[key] = data;
        dim.dataStorer[key] = msg.sender; // Record who stored it
        collectedFees += dataStorageCost; // Collect the fee

        emit DataStored(dimensionId, msg.sender, key, data.length);

        // Refund excess ETH
        if (msg.value > dataStorageCost) {
            (bool success, ) = msg.sender.call{value: msg.value - dataStorageCost}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @notice Allows a user to pay for an "analysis" of a dimension.
     * @dev Represents a user request that might trigger off-chain computation or system action.
     * @param dimensionId The ID of the dimension to analyze.
     */
    function requestDimensionAnalysis(uint256 dimensionId)
        external
        payable
        dimensionExists(dimensionId)
    {
        // Arbitrary cost for analysis request
        uint256 analysisCost = 0.005 ether;
        if (msg.value < analysisCost)
             revert("Insufficient ETH for analysis request");

        collectedFees += analysisCost; // Collect the fee

        emit AnalysisRequested(dimensionId, msg.sender, analysisCost);

        // Refund excess ETH
        if (msg.value > analysisCost) {
            (bool success, ) = msg.sender.call{value: msg.value - analysisCost}("");
            require(success, "Refund failed");
        }
        // Contract state is updated by the event; off-chain listeners would pick this up.
    }


    // --- System Mechanics (Triggerable) ---

    /**
     * @notice Triggers the stability decay calculation for a single dimension based on time elapsed.
     * @dev Anyone can call this function. Incentives for calling this (e.g., small reward) could be added.
     * @param dimensionId The ID of the dimension to decay.
     */
    function decaySingleDimensionStability(uint256 dimensionId)
        external
        dimensionExists(dimensionId)
    {
        Dimension storage dim = dimensions[dimensionId];
        uint256 timeElapsed = block.timestamp - dim.lastStabilityDecayTimestamp;

        if (timeElapsed == 0) {
            // No time has passed since last decay calculation for this block
            return;
        }

        uint256 oldStability = dim.stability;

        // Calculate decay amount: stability * decayRate * timeElapsed
        // Use fixed-point arithmetic (decayRate scaled by 1e18)
        // decayAmount = (stability * decayRate * timeElapsed) / 1e18
        uint256 decayAmount = (dim.stability * stabilityDecayRate * timeElapsed) / 1e18;

        if (decayAmount > dim.stability) {
             dim.stability = 0;
        } else {
             dim.stability -= decayAmount;
        }


        dim.lastStabilityDecayTimestamp = uint264(block.timestamp);

        emit StabilityDecayed(dimensionId, oldStability, dim.stability, decayAmount);
    }

    /**
     * @notice Triggers a check for a potential anomaly in a random dimension.
     * @dev Uses blockhash for pseudo-randomness (known limitation). Anyone can call.
     * Anomaly chance increases with anomalyRisk and decreases with stability.
     */
    function triggerRandomAnomalyCheck() external {
        uint256 totalDimensions = dimensionIds.length;
        if (totalDimensions == 0) return;

        // Pseudo-random selection of a dimension
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender))) % totalDimensions;
        uint256 randomDimensionId = dimensionIds[randomIndex];

        Dimension storage dim = dimensions[randomDimensionId];

        // Calculate anomaly chance (simplified example logic)
        // Risk = anomalyRisk (0-10000)
        // Stability = dim.stability
        // AnomalyChance = (Risk * MaxStability) / (Stability + MaxStability) ? No, simpler.
        // Chance is proportional to risk, inversely proportional to stability.
        // Let's use: chance = risk * RiskFactor / (stability + SomeBase)
        // RiskFactor could be 1e6. Chance is 0-10000.
        uint256 calculatedChance;
        if (dim.stability == 0) {
            calculatedChance = dim.anomalyRisk; // Max risk if no stability
        } else {
             // Example: Chance = (anomalyRisk * 1e6) / stability
             // Using 1e18 as base for stability for scaling consistency
             uint256 baseStability = 1e18; // Example base for scaling stability
             if (dim.stability < baseStability) {
                 // If stability is low, risk is higher
                 calculatedChance = (dim.anomalyRisk * baseStability) / (dim.stability + 1); // +1 to avoid division by zero
             } else {
                 // If stability is high, risk is lower, caps at anomalyRisk/scaling
                 calculatedChance = dim.anomalyRisk / ((dim.stability / baseStability) + 1);
             }
        }

        // Clamp calculatedChance to max possible risk scale
        if (calculatedChance > 10000) {
             calculatedChance = 10000;
        }


        // Generate random number 0-9999
        uint256 randomValue = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, randomDimensionId))) % 10000;

        if (randomValue < calculatedChance) {
            // Anomaly occurs!
            uint256 anomalyType = (randomValue % 3) + 1; // Example: 3 types of anomalies
            string memory description = "Unspecified Anomaly";
            if (anomalyType == 1) description = "Minor Energy Fluctuation";
            else if (anomalyType == 2) description = "Temporal Distortion Detected";
            else if (anomalyType == 3) description = "Dimensional Resonance Spike";

            // Example anomaly effect: reduce stability significantly
            uint256 stabilityLoss = dim.stability / ((randomValue % 10) + 2); // Lose 1/2 to 1/11 of stability
            if (stabilityLoss > dim.stability) stabilityLoss = dim.stability;
            dim.stability -= stabilityLoss;


            emit AnomalyDetected(randomDimensionId, anomalyType, description);

            // More complex effects (e.g., altering properties, locking interactions) could be added here.
        }
    }

    /**
     * @notice Links two dimensions together.
     * @dev Currently restricted to the owner. Could require stability thresholds or other conditions.
     * @param dimension1Id The ID of the first dimension.
     * @param dimension2Id The ID of the second dimension.
     */
    function linkDimensions(uint256 dimension1Id, uint256 dimension2Id)
        external
        onlyOwner // Restricted for simplicity; could be conditional
        dimensionExists(dimension1Id)
        dimensionExists(dimension2Id)
    {
        if (dimension1Id == dimension2Id) revert CannotLinkToSelf();

        // Check if link already exists (bi-directional check)
        bool linkExists = false;
        uint256[] storage links1 = linkedDimensions[dimension1Id];
        for (uint256 i = 0; i < links1.length; i++) {
            if (links1[i] == dimension2Id) {
                linkExists = true;
                break;
            }
        }

        if (linkExists) revert LinkAlreadyExists(dimension1Id, dimension2Id);

        // Add link to both dimensions' lists
        linkedDimensions[dimension1Id].push(dimension2Id);
        linkedDimensions[dimension2Id].push(dimension1Id); // Keep links symmetric

        emit DimensionsLinked(dimension1Id, dimension2Id, msg.sender);
    }


    // --- View Functions ---

    /**
     * @notice Retrieves the core details of a specific dimension.
     * @param dimensionId The ID of the dimension.
     * @return id Dimension ID.
     * @return stability Current stability.
     * @return explorationCostBase Base exploration cost for this dimension.
     * @return stabilityThreshold Stability threshold for this dimension.
     * @return anomalyRisk Anomaly risk (0-10000).
     * @return lastStabilityDecayTimestamp Timestamp of last decay calculation.
     * @return totalInteractionCount Total times explored.
     * @return creationTimestamp Timestamp of creation.
     * @return interactionFee Additional interaction fee.
     */
    function getDimensionDetails(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (
            uint256 id,
            uint256 stability,
            uint256 explorationCostBase,
            uint256 stabilityThreshold,
            uint256 anomalyRisk,
            uint264 lastStabilityDecayTimestamp,
            uint256 totalInteractionCount,
            uint256 creationTimestamp,
            uint256 interactionFee
        )
    {
        Dimension storage dim = dimensions[dimensionId];
        return (
            dim.id,
            dim.stability,
            dim.explorationCostBase,
            dim.stabilityThreshold,
            dim.anomalyRisk,
            dim.lastStabilityDecayTimestamp,
            dim.totalInteractionCount,
            dim.creationTimestamp,
            dim.interactionFee
        );
    }

    /**
     * @notice Returns an array of all existing dimension IDs.
     * @dev Gas cost increases linearly with the number of dimensions.
     * @return An array of dimension IDs.
     */
    function listDimensionIds() external view returns (uint256[] memory) {
        return dimensionIds;
    }

    /**
     * @notice Retrieves the total ETH contributed by a specific user to a specific dimension's stability.
     * @param dimensionId The ID of the dimension.
     * @param explorer The address of the user.
     * @return The total ETH contributed by the user in Wei.
     */
    function getUserDimensionContribution(uint256 dimensionId, address explorer)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        return dimensions[dimensionId].userContributions[explorer];
    }

    /**
     * @notice Retrieves stored data for a given dimension and key.
     * @param dimensionId The ID of the dimension.
     * @param key The bytes32 key for the data entry.
     * @return The bytes data associated with the key, or empty bytes if not found.
     */
    function retrieveDimensionData(uint256 dimensionId, bytes32 key)
        external
        view
        dimensionExists(dimensionId)
        returns (bytes memory)
    {
        bytes memory data = dimensions[dimensionId].dataStorage[key];
        // Optional: check if data exists and revert if not, or return empty bytes
        // if (data.length == 0 && dimensions[dimensionId].dataStorer[key] == address(0)) revert NoDataForKey(dimensionId, key);
        return data;
    }

     /**
     * @notice Returns the total number of times a dimension has been explored.
     * @param dimensionId The ID of the dimension.
     * @return The total exploration count.
     */
    function getDimensionInteractionCount(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        return dimensions[dimensionId].totalInteractionCount;
    }

    /**
     * @notice Returns the current stability level of a dimension.
     * @param dimensionId The ID of the dimension.
     * @return The current stability value.
     */
    function getDimensionStability(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        // Note: This view function does *not* trigger decay. Decay must be triggered externally.
        return dimensions[dimensionId].stability;
    }

    /**
     * @notice Calculates the current ETH cost to explore a dimension, which can be dynamic.
     * @dev Example logic: Base cost * (1 + (AnomalyRisk / MaxRisk) * (MaxStability / (Stability + 1))).
     * This makes low stability/high risk dimensions potentially more expensive.
     * @param dimensionId The ID of the dimension.
     * @return The calculated exploration cost in Wei.
     */
    function calculateCurrentExplorationCost(uint256 dimensionId)
        public // Made public so other internal functions can call
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        Dimension storage dim = dimensions[dimensionId];
        uint256 currentBaseCost = dim.explorationCostBase > 0 ? dim.explorationCostBase : explorationBaseCost; // Use dimension specific or global base

        // Simplified dynamic cost calculation: cost increases as stability decreases or risk increases
        // Cost Factor = 1 + (AnomalyRisk / 10000) * (MaxPossibleStability / (CurrentStability + 1))
        // MaxPossibleStability is unknown/unbounded, use a scaling factor
        uint256 stabilityScalingFactor = 1e18; // Assume 1 ETH contribution adds this much stability

        uint256 stabilityBasedFactor;
        if (dim.stability == 0) {
            stabilityBasedFactor = 2e18; // Max factor if 0 stability (scaled by 1e18)
        } else {
             // Factor decreases as stability increases
             // Example: scaling factor = 1e18 / (dim.stability / stabilityScalingFactor + 1)
             stabilityBasedFactor = stabilityScalingFactor * 1e18 / (dim.stability + stabilityScalingFactor); // Add scaling factor to avoid division by very small numbers
        }


        // Risk factor scaled 0-1e18 from 0-10000 risk
        uint256 riskFactor = (dim.anomalyRisk * 1e18) / 10000;

        // Combine factors (example): cost increases with risk and decreases with stability
        // Total Factor = 1e18 + riskFactor + stabilityBasedFactor (scaled)
        uint256 totalFactor = 1e18 + riskFactor + stabilityBasedFactor;

        // Final cost = currentBaseCost * totalFactor / 1e18
        return (currentBaseCost * totalFactor) / 1e18;
    }


    /**
     * @notice Returns an array of dimensions linked to the given dimension.
     * @param dimensionId The ID of the dimension.
     * @return An array of linked dimension IDs.
     */
    function getLinkedDimensions(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256[] memory)
    {
        return linkedDimensions[dimensionId];
    }

    /**
     * @notice Returns the current interaction fee for a dimension.
     * @param dimensionId The ID of the dimension.
     * @return The interaction fee in Wei.
     */
    function getDimensionInteractionFee(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        return dimensions[dimensionId].interactionFee;
    }

    /**
     * @notice Returns the anomaly risk parameter for a dimension.
     * @param dimensionId The ID of the dimension.
     * @return The anomaly risk (0-10000).
     */
    function getAnomalyRiskDetails(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        return dimensions[dimensionId].anomalyRisk;
    }

    /**
     * @notice Calculates and returns the sum of stability across all dimensions.
     * @dev Can be gas-intensive if there are many dimensions.
     * @return The total stability of the system.
     */
    function getTotalStability() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < dimensionIds.length; i++) {
            // Note: This sums current state, doesn't trigger decay for all before summing.
            total += dimensions[dimensionIds[i]].stability;
        }
        return total;
    }

    /**
     * @notice Returns a list of dimension IDs with stability greater than or equal to a threshold.
     * @dev Can be gas-intensive if there are many dimensions.
     * @param minStability The minimum stability required.
     * @return An array of dimension IDs meeting the threshold.
     */
    function getDimensionsByStabilityThreshold(uint256 minStability)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory stableDimensions = new uint256[](dimensionIds.length); // Max size
        uint256 count = 0;
        for (uint256 i = 0; i < dimensionIds.length; i++) {
            uint256 dimId = dimensionIds[i];
            if (dimensions[dimId].stability >= minStability) {
                stableDimensions[count] = dimId;
                count++;
            }
        }
        // Resize the array to actual count
        uint264[] memory result = new uint264[](count); // Use uint264 to save gas on memory copy? No, must be same type.
        uint256[] memory result_ = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
            result_[i] = stableDimensions[i];
        }
        return result_;
    }

    /**
     * @notice Gets the tags associated with a dimension.
     * @dev Returns the stored tagList array.
     * @param dimensionId The ID of the dimension.
     * @return An array of strings representing the tags.
     */
    function getDimensionTags(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (string[] memory)
    {
        return dimensions[dimensionId].tagList;
    }

    /**
     * @notice Gets the list of dimensions that a specific explorer has interacted with (explored).
     * @param explorer The address of the explorer.
     * @return An array of dimension IDs the explorer has explored.
     */
    function getExplorerDimensions(address explorer) external view returns (uint256[] memory) {
        return explorerDimensions[explorer];
    }

     /**
     * @notice Returns the timestamp when a dimension was created.
     * @param dimensionId The ID of the dimension.
     * @return The creation timestamp (Unix time).
     */
    function getDimensionCreationTimestamp(uint256 dimensionId)
        external
        view
        dimensionExists(dimensionId)
        returns (uint256)
    {
        return dimensions[dimensionId].creationTimestamp;
    }

    // Function 35+ could involve...
    // - Querying data keys for a dimension (gas intensive)
    // - Transferring dimension ownership (if dimensions were NFTS?)
    // - Setting dynamic properties based on global state
    // - A complex "mergeDimensions" mechanic (very complex state changes)
    // - A complex "splitDimension" mechanic
    // - Allowing users to propose changes to dimension parameters (governance)
    // - Integrating with an oracle for external data affecting anomalies/decay
    // - Time-locked actions within a dimension
    // - Auctions or sales of dimensions/data slots

    // The current 34 functions provide a good mix of state management,
    // user interaction, system mechanics, and varied view functions,
    // fulfilling the requirement for >= 20 functions with advanced concepts.

}
```