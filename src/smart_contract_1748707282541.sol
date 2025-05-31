Okay, here is a Solidity smart contract concept called `QuantumFluxChronicle`.

This contract focuses on dynamic, time-sensitive, and interconnected digital assets ("Chronicles"). Each Chronicle is an NFT (ERC721) with properties that change over time based on internal 'Flux' energy, interactions with other Chronicles (via 'Entanglement'), external 'Temporal Anomalies' (simulated via an oracle), and owner actions like 'Stabilization' or attempting a 'Dimensional Shift'. It also includes a snapshot mechanism for preserving specific states.

This concept combines elements of:
1.  **Dynamic NFTs:** Properties change based on logic.
2.  **Resource Management:** Chronicles have 'Flux' (accrues, spent on actions) and 'Temporal Anchor' (consumed, provides stability).
3.  **Inter-Asset Relationship:** The 'Entanglement' feature creates a network effect between NFTs.
4.  **Time Dependency:** State changes are heavily influenced by time elapsed.
5.  **External Data Influence:** An 'Oracle' simulates external 'Temporal Anomalies' affecting the ecosystem.
6.  **State Snapshotting:** A basic mechanism to save/restore *some* properties.

It aims to be novel by combining these mechanics into a single, themed system, rather than just implementing one in isolation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// 1. Contract Definition and Imports
// 2. Error Definitions
// 3. Structs: Define the data structures for Chronicles, Snapshots, and Anomalies.
// 4. State Variables: Store contract data (Chronicles, Snapshots, Anomalies, Oracle, Counters, etc.).
// 5. Events: Announce significant actions and state changes.
// 6. Modifiers: Restrict access to specific functions (e.g., onlyOracle).
// 7. Internal Helper Functions: Logic encapsulated for clarity and reuse (e.g., state calculation).
// 8. ERC721 Functions: Standard NFT operations inherited from OpenZeppelin.
// 9. Core Chronicle Functions: Minting and primary state management.
// 10. Resource Management Functions: Interacting with Flux and Anchor.
// 11. Entanglement Functions: Managing links between Chronicles.
// 12. Snapshot Functions: Capturing and restoring Chronicle states.
// 13. Temporal Anomaly Functions: Oracle interaction and processing impacts.
// 14. Dynamic Property Management Functions: Adding/updating custom properties.
// 15. Query/View Functions: Reading various aspects of the contract state.
// 16. Admin Functions: Owner-only operations.

// --- Function Summary ---
// ERC721 Standard (Inherited & Overridden):
// 1.  balanceOf(address owner) view: Returns the number of tokens in owner's account.
// 2.  ownerOf(uint256 tokenId) view: Returns the owner of the tokenId.
// 3.  transferFrom(address from, address to, uint256 tokenId): Transfers ownership of a token.
// 4.  approve(address to, uint256 tokenId): Approves address `to` to transfer `tokenId`.
// 5.  setApprovalForAll(address operator, bool approved): Approves/disapproves operator for all tokens.
// 6.  getApproved(uint256 tokenId) view: Returns the approved address for a token.
// 7.  isApprovedForAll(address owner, address operator) view: Returns if operator is approved for owner.
// 8.  totalSupply() view: Returns total number of tokens in existence (from ERC721Enumerable).
// 9.  tokenOfOwnerByIndex(address owner, uint256 index) view: Returns a token ID owned by `owner` at a given index (from ERC721Enumerable).
// 10. tokenByIndex(uint256 index) view: Returns a token ID at a given index across all tokens (from ERC721Enumerable).

// Core Chronicle Functions:
// 11. mintChronicle(address owner, uint256 initialFlux, uint256 initialStability, uint256 initialAnchor): Mints a new Chronicle NFT to `owner` with initial stats.
// 12. updateChronicleState(uint256 tokenId): Public helper to trigger state recalculation for a token (gas management consideration).

// Resource Management Functions:
// 13. stabilizeTemporalFlux(uint256 tokenId, uint256 anchorToSpend): Uses Dimensional Anchor to boost Temporal Stability.
// 14. triggerDimensionalShift(uint256 tokenId, uint256 fluxToSpend, uint256 anchorToSpend): Attempts a random property change, consuming resources.

// Entanglement Functions:
// 15. entangleChronicles(uint256 tokenId1, uint256 tokenId2, uint256 fluxToSpend, uint256 anchorToSpend): Links two owned Chronicles, requiring resource cost.
// 16. dissipateEntanglement(uint256 tokenId1, uint256 tokenId2): Breaks the link between two entangled Chronicles.
// 17. transferFlux(uint256 fromTokenId, uint256 toTokenId, uint256 amount): Transfers Flux between two *entangled* Chronicles owned by the caller.
// 18. harmonizeProperties(uint256 tokenId1, uint256 tokenId2, uint256 fluxToSpend): Attempts to average or blend properties between two entangled Chronicles.

// Snapshot Functions:
// 19. captureTemporalSnapshot(uint256 tokenId): Saves the current state of a Chronicle as a Snapshot.
// 20. restoreFromSnapshot(uint256 tokenId, uint256 snapshotId, uint256 fluxToSpend, uint256 anchorToSpend): Restores a Chronicle's state to a saved Snapshot, consuming resources.

// Temporal Anomaly Functions:
// 21. registerTemporalAnomaly(string calldata description, uint256 magnitude, bytes calldata data): Callable by Oracle role to log a new Anomaly.
// 22. processAnomalyImpact(): Callable by Oracle role or Owner to process the effects of recent Anomalies on all Chronicles.

// Dynamic Property Management Functions:
// 23. addChroniclePropertyUint(uint256 tokenId, string calldata key, uint256 value): Adds or updates a uint256 property.
// 24. addChroniclePropertyString(uint256 tokenId, string calldata key, string calldata value): Adds or updates a string property.
// 25. addChroniclePropertyBool(uint256 tokenId, string calldata key, bool value): Adds or updates a boolean property.
// 26. removeChroniclePropertyUint(uint256 tokenId, string calldata key): Removes a uint256 property.
// 27. removeChroniclePropertyString(uint256 tokenId, string calldata key): Removes a string property.
// 28. removeChroniclePropertyBool(uint256 tokenId, string calldata key): Removes a boolean property.

// Query/View Functions:
// 29. getFluxEnergy(uint256 tokenId) view: Returns the current calculated Flux energy.
// 30. getTemporalStability(uint256 tokenId) view: Returns the current calculated Temporal Stability.
// 31. getDimensionalAnchor(uint256 tokenId) view: Returns the current calculated Dimensional Anchor.
// 32. getChroniclePropertiesUint(uint256 tokenId, string calldata key) view: Gets a specific uint256 property.
// 33. getChroniclePropertiesString(uint256 tokenId, string calldata key) view: Gets a specific string property.
// 34. getChroniclePropertiesBool(uint256 tokenId, string calldata key) view: Gets a specific boolean property.
// 35. getEntangledChronicles(uint256 tokenId) view: Returns list of token IDs this Chronicle is entangled with.
// 36. getAnomalyHistory(uint256 startIndex, uint256 endIndex) view: Returns a range of recent Anomaly events.
// 37. getChronicleCreationTime(uint256 tokenId) view: Returns the timestamp of creation.
// 38. getTimeSinceLastAnomaly() view: Returns time elapsed since the last registered Anomaly.
// 39. calculatePredictedFlux(uint256 tokenId, uint256 timeDelta) view: Estimates Flux after `timeDelta` based on current state and rules.
// 40. getSnapshotCount(uint256 tokenId) view: Returns the number of snapshots for a Chronicle.
// 41. getSnapshotData(uint256 snapshotId) view: Returns data for a specific snapshot.

// Admin Functions:
// 42. setOracleAddress(address _oracle): Sets the address allowed to register Anomalies.
// 43. pauseAnomalies(bool _paused): Pauses/unpauses the processing of Temporal Anomalies.
// 44. setBaseFluxRate(uint256 rate): Sets the base rate at which Flux accrues over time.

// --- Contract Implementation ---

contract QuantumFluxChronicle is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error NotOracle();
    error AnomaliesPaused();
    error InvalidTokenId();
    error NotChronicleOwner();
    error InsufficientFlux();
    error InsufficientAnchor();
    error ChroniclesAlreadyEntangled();
    error ChroniclesNotEntangled();
    error CannotEntangleSelf();
    error InsufficientSnapshotCount();
    error InvalidSnapshotId();
    error CannotTransferFluxToSelf();
    error PropertyNotFound();
    error InvalidAnomalyIndexRange();

    // --- Structs ---
    struct Chronicle {
        uint256 fluxEnergy;          // Resource: Accrues over time, used for actions
        uint256 temporalStability;   // State: Resists Anomaly impact and decay
        uint256 dimensionalAnchor;   // Resource: Consumed for actions, provides stability
        uint64 creationTimestamp;    // When the Chronicle was minted
        uint64 lastStateUpdateTimestamp; // When state variables were last explicitly updated

        // Dynamic Properties using mappings
        mapping(string => uint256) propertiesUint;
        mapping(string => string) propertiesString;
        mapping(string => bool) propertiesBool;
        // bytes property type omitted for simplicity, could be added

        uint256[] entangledWith;     // Array of token IDs this Chronicle is entangled with
        uint256[] snapshotIds;       // Array of snapshot IDs associated with this Chronicle
    }

    struct Snapshot {
        uint256 fluxEnergy;
        uint256 temporalStability;
        uint256 dimensionalAnchor;
        uint64 timestamp;
        // Store a subset of key properties, not all mappings directly
        mapping(string => uint256) propertiesUintSubset;
        // Add other relevant property subsets if needed
    }

    struct TemporalAnomaly {
        string description;
        uint64 timestamp;
        uint256 magnitude; // Represents the intensity/impact of the anomaly
        bytes data;        // Optional additional data
    }

    // --- State Variables ---
    mapping(uint256 => Chronicle) private _chronicles;
    mapping(uint256 => Snapshot) private _snapshots;
    TemporalAnomaly[] private _anomalyHistory;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _snapshotIdCounter;

    address private _oracleAddress;
    uint256 private _baseFluxRate = 100; // Base flux per unit time (e.g., per hour)

    bool private _anomaliesPaused = false;
    uint64 private _lastAnomalyTimestamp = uint64(block.timestamp);

    // --- Events ---
    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event StateUpdated(uint256 indexed tokenId, uint64 timestamp);
    event TemporalAnomalyRegistered(uint256 indexed anomalyIndex, uint64 timestamp, string description);
    event AnomalyImpactProcessed(uint64 timestamp);
    event EntanglementCreated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint64 timestamp);
    event EntanglementDissipated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint64 timestamp);
    event FluxTransferred(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 amount, uint64 timestamp);
    event PropertiesHarmonized(uint256 indexed tokenId1, uint256 indexed tokenId2, uint64 timestamp);
    event DimensionalShiftTriggered(uint256 indexed tokenId, uint64 timestamp);
    event SnapshotCaptured(uint256 indexed tokenId, uint256 indexed snapshotId, uint64 timestamp);
    event StateRestoredFromSnapshot(uint256 indexed tokenId, uint256 indexed snapshotId, uint64 timestamp);
    event ChroniclePropertyChanged(uint256 indexed tokenId, string key, uint64 timestamp);

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) revert NotOracle();
        _;
    }

    modifier onlyOwnerOrOracle() {
        if (msg.sender != owner() && msg.sender != _oracleAddress) revert Ownable.OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    modifier onlyChronicleOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert NotChronicleOwner();
        _;
    }

    modifier onlyEntangled(uint256 tokenId1, uint256 tokenId2) {
        bool isEntangled = false;
        for (uint i = 0; i < _chronicles[tokenId1].entangledWith.length; i++) {
            if (_chronicles[tokenId1].entangledWith[i] == tokenId2) {
                isEntangled = true;
                break;
            }
        }
        if (!isEntangled) revert ChroniclesNotEntangled();
        _;
    }


    // --- Constructor ---
    constructor(address oracleAddress_) ERC721("QuantumFluxChronicle", "QFC") Ownable(msg.sender) {
        _oracleAddress = oracleAddress_;
        // Initialize genesis anomaly to set _lastAnomalyTimestamp
        _anomalyHistory.push(TemporalAnomaly("Genesis", uint64(block.timestamp), 0, ""));
    }

    // --- Internal Helper Functions ---

    // @dev Internal function to calculate and update the dynamic state of a Chronicle.
    //      This is the core logic for Flux accrual, decay, and Anomaly impact.
    //      Called before reading or modifying state, or explicitly via updateChronicleState.
    function _calculateAndUpdateChronicleState(uint256 tokenId) internal {
        Chronicle storage chronicle = _chronicles[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - chronicle.lastStateUpdateTimestamp;

        if (timeElapsed > 0) {
            // Flux accrual: Base rate + potential bonus from properties or entanglement (simplified here)
            chronicle.fluxEnergy += _baseFluxRate * timeElapsed;

            // Temporal Stability decay: Stability decreases over time
            // Simplified decay: Reduce stability by a percentage or flat rate based on timeElapsed
            uint256 stabilityDecay = (chronicle.temporalStability * timeElapsed) / 1000; // Example: 0.1% decay per unit time
            if (stabilityDecay >= chronicle.temporalStability) {
                 chronicle.temporalStability = 0;
            } else {
                 chronicle.temporalStability -= stabilityDecay;
            }


            // Apply Anomaly impact if not paused and new anomalies occurred since last update
            if (!_anomaliesPaused && _lastAnomalyTimestamp > chronicle.lastStateUpdateTimestamp) {
                _applyAnomalyImpact(tokenId);
            }

            // Apply Entanglement effects (simplified: shared flux or stability checks)
            // This could be a complex function iterating entangledWith and modifying states
            _applyEntanglementEffects(tokenId);


            chronicle.lastStateUpdateTimestamp = currentTime;

            emit StateUpdated(tokenId, currentTime);
        }
    }

    // @dev Internal function to apply effects from recent anomalies to a single chronicle.
    //      Called by _calculateAndUpdateChronicleState or processAnomalyImpact.
    function _applyAnomalyImpact(uint256 tokenId) internal {
        Chronicle storage chronicle = _chronicles[tokenId];
        uint64 processStartTime = chronicle.lastStateUpdateTimestamp; // Only process anomalies since last update

        // Iterate through anomalies registered since the last update time
        // Note: This can be gas intensive if many anomalies or many chronicles.
        // A more scalable approach might involve off-chain processing or different impact models.
        uint startIdx = 0;
        for (uint i = 0; i < _anomalyHistory.length; i++) {
             if (_anomalyHistory[i].timestamp > processStartTime) {
                 startIdx = i;
                 break;
             }
             // If no anomalies found after processStartTime, nothing to do
             if (i == _anomalyHistory.length - 1) return;
        }

        for (uint i = startIdx; i < _anomalyHistory.length; i++) {
            TemporalAnomaly storage anomaly = _anomalyHistory[i];
            uint256 effectiveMagnitude = anomaly.magnitude;

            // Anomaly impact resisted by Temporal Stability (simplified)
            // Higher stability reduces effective magnitude
            uint256 resistance = chronicle.temporalStability / 100; // Example: 100 stability reduces magnitude by 1
            if (effectiveMagnitude > resistance) {
                effectiveMagnitude -= resistance;
            } else {
                effectiveMagnitude = 0;
            }

            if (effectiveMagnitude > 0) {
                 // Example impacts (customize heavily based on desired game mechanics):
                 // - Reduce Flux Energy
                 // - Reduce Dimensional Anchor
                 // - Reduce Temporal Stability further
                 // - Randomly change properties based on data/magnitude
                 // - Potentially affect entangled chronicles

                 uint256 fluxReduction = effectiveMagnitude * 10; // Example calculation
                 if (chronicle.fluxEnergy > fluxReduction) {
                     chronicle.fluxEnergy -= fluxReduction;
                 } else {
                     chronicle.fluxEnergy = 0;
                 }

                 uint256 anchorReduction = effectiveMagnitude / 5; // Example calculation
                 if (chronicle.dimensionalAnchor > anchorReduction) {
                      chronicle.dimensionalAnchor -= anchorReduction;
                 } else {
                     chronicle.dimensionalAnchor = 0;
                 }

                 // More complex impacts based on anomaly.data would go here
             }
        }
    }

    // @dev Internal function to apply effects between entangled chronicles.
    //      Called by _calculateAndUpdateChronicleState.
    function _applyEntanglementEffects(uint256 tokenId) internal {
        Chronicle storage chronicle = _chronicles[tokenId];
        // Simplified: Entangled chronicles contribute a small amount of flux to each other
        uint256 sharedFluxPerLink = _baseFluxRate / 10; // Example: 10% of base rate per link

        chronicle.fluxEnergy += sharedFluxPerLink * chronicle.entangledWith.length;

        // More complex effects could include:
        // - Averaging stability/anchor across entangled group
        // - Triggering joint events if a specific condition is met within the group
        // - Amplifying/reducing anomaly impacts based on group state
    }

    // @dev Internal function to ensure a token ID exists.
    function _exists(uint256 tokenId) internal view override returns (bool) {
        // Standard ERC721 checks are usually sufficient, but explicitly check our mapping if needed
        return super._exists(tokenId); // Assumes OpenZeppelin's _exists checks against its internal state
    }

    // @dev Helper to get chronicle struct with state updated
    function _getChronicle(uint256 tokenId) internal returns (Chronicle storage) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        _calculateAndUpdateChronicleState(tokenId); // Ensure state is current before returning
        return _chronicles[tokenId];
    }

    // @dev Internal helper to remove an element from a uint256 array
    function _removeFromArray(uint256[] storage arr, uint256 value) internal {
        uint256 index = arr.length; // Initialize with out of bounds
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                index = i;
                break;
            }
        }

        if (index < arr.length) {
            // Replace element with the last one and shrink array
            arr[index] = arr[arr.length - 1];
            arr.pop();
        }
    }


    // --- ERC721 Functions ---
    // Overrides from ERC721Enumerable and ERC721 standard are implicitly handled by inheritance.
    // No need to list balancef, ownerOf, transferFrom etc. here unless custom logic is added.
    // We will override _update and _transfer if needed for hooks, but not necessary for basic function list count.

    // --- Core Chronicle Functions ---

    /// @notice Mints a new Quantum Flux Chronicle NFT.
    /// @param owner The address to mint the Chronicle to.
    /// @param initialFlux Initial amount of Flux Energy.
    /// @param initialStability Initial Temporal Stability value.
    /// @param initialAnchor Initial Dimensional Anchor value.
    function mintChronicle(address owner, uint256 initialFlux, uint256 initialStability, uint256 initialAnchor) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(owner, newItemId);

        Chronicle storage newChronicle = _chronicles[newItemId];
        newChronicle.fluxEnergy = initialFlux;
        newChronicle.temporalStability = initialStability;
        newChronicle.dimensionalAnchor = initialAnchor;
        newChronicle.creationTimestamp = uint64(block.timestamp);
        newChronicle.lastStateUpdateTimestamp = uint64(block.timestamp); // Initialize last update time

        emit ChronicleMinted(newItemId, owner, uint64(block.timestamp));
    }

    /// @notice Public function to trigger state calculation for a Chronicle.
    /// @dev This allows owners or others to pay gas to update a Chronicle's state explicitly,
    ///      rather than relying solely on internal calls before state reads/writes.
    /// @param tokenId The ID of the Chronicle to update.
    function updateChronicleState(uint256 tokenId) external {
        // Anyone can call this to force an update, paying the gas.
        // Ownership check is not required as this is a read/passive update trigger.
        _calculateAndUpdateChronicleState(tokenId);
        // Event is emitted inside _calculateAndUpdateChronicleState
    }


    // --- Resource Management Functions ---

    /// @notice Uses Dimensional Anchor to boost Temporal Stability.
    /// @param tokenId The Chronicle ID.
    /// @param anchorToSpend The amount of Dimensional Anchor to consume.
    function stabilizeTemporalFlux(uint256 tokenId, uint256 anchorToSpend) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first

        if (chronicle.dimensionalAnchor < anchorToSpend) revert InsufficientAnchor();

        chronicle.dimensionalAnchor -= anchorToSpend;
        // Stability boost logic: Example 1 Anchor = 10 Stability
        chronicle.temporalStability += anchorToSpend * 10;

        // Optional: Add event for stabilization
    }

    /// @notice Attempts a Dimensional Shift, consuming Flux and Anchor for a chance at new properties.
    /// @dev This introduces a degree of randomness. The outcome could be positive, negative, or neutral.
    ///      Uses block data for pseudo-randomness; a real dApp might use Chainlink VRF.
    /// @param tokenId The Chronicle ID.
    /// @param fluxToSpend The amount of Flux Energy to consume.
    /// @param anchorToSpend The amount of Dimensional Anchor to consume.
    function triggerDimensionalShift(uint256 tokenId, uint256 fluxToSpend, uint256 anchorToSpend) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first

        if (chronicle.fluxEnergy < fluxToSpend) revert InsufficientFlux();
        if (chronicle.dimensionalAnchor < anchorToSpend) revert InsufficientAnchor();

        chronicle.fluxEnergy -= fluxToSpend;
        chronicle.dimensionalAnchor -= anchorToSpend;

        // --- Pseudo-random outcome logic ---
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, fluxToSpend, anchorToSpend)));

        // Example: Based on randomness, modify certain uint properties
        // This is a simplified example. Real logic could be complex.
        uint256 outcome = randomness % 100; // 0-99

        if (outcome < 30) { // 30% chance of positive shift
            // Increase some random uint property significantly
            // (Need to get keys from mapping - complex in Solidity. Simplification: target specific known properties)
            // chronicle.propertiesUint["some_key"] += randomness % 1000; // Example
            // Let's just boost Flux/Stability as a positive outcome for simplicity in this draft
             chronicle.fluxEnergy += (fluxToSpend * 2); // Gain back double spent flux
             chronicle.temporalStability += anchorToSpend * 20; // Double stability gain compared to stabilize action

        } else if (outcome < 70) { // 40% chance of neutral shift (minor change or no change)
             // Slightly adjust a property or gain a small resource amount
             chronicle.fluxEnergy += fluxToSpend / 4; // Gain back small amount of flux

        } else { // 30% chance of negative shift
             // Decrease a random property or lose more resources
             uint256 stabilityLoss = chronicle.temporalStability / 4;
             if (stabilityLoss > 0) chronicle.temporalStability -= stabilityLoss;
        }

        emit DimensionalShiftTriggered(tokenId, uint64(block.timestamp));
    }

    // --- Entanglement Functions ---

    /// @notice Links two owned Chronicles together, creating Entanglement.
    /// @dev Entangled Chronicles can interact in unique ways (e.g., share flux, affect each other's stability).
    /// @param tokenId1 The ID of the first Chronicle.
    /// @param tokenId2 The ID of the second Chronicle.
    /// @param fluxToSpend The amount of Flux Energy required from *each* Chronicle.
    /// @param anchorToSpend The amount of Dimensional Anchor required from *each* Chronicle.
    function entangleChronicles(uint256 tokenId1, uint256 tokenId2, uint256 fluxToSpend, uint256 anchorToSpend) external onlyChronicleOwner(tokenId1) {
        if (ownerOf(tokenId2) != msg.sender) revert NotChronicleOwner(); // Both must be owned by caller
        if (tokenId1 == tokenId2) revert CannotEntangleSelf();

        Chronicle storage chronicle1 = _getChronicle(tokenId1); // Update state
        Chronicle storage chronicle2 = _getChronicle(tokenId2); // Update state

        // Check if already entangled (simple check, could be optimized for many links)
        for (uint i = 0; i < chronicle1.entangledWith.length; i++) {
            if (chronicle1.entangledWith[i] == tokenId2) revert ChroniclesAlreadyEntangled();
        }

        if (chronicle1.fluxEnergy < fluxToSpend || chronicle2.fluxEnergy < fluxToSpend) revert InsufficientFlux();
        if (chronicle1.dimensionalAnchor < anchorToSpend || chronicle2.dimensionalAnchor < anchorToSpend) revert InsufficientAnchor();

        chronicle1.fluxEnergy -= fluxToSpend;
        chronicle2.fluxEnergy -= fluxToSpend;
        chronicle1.dimensionalAnchor -= anchorToSpend;
        chronicle2.dimensionalAnchor -= anchorToSpend;

        chronicle1.entangledWith.push(tokenId2);
        chronicle2.entangledWith.push(tokenId1); // Entanglement is bidirectional

        emit EntanglementCreated(tokenId1, tokenId2, uint64(block.timestamp));
    }

    /// @notice Dissipates the Entanglement between two owned Chronicles.
    /// @param tokenId1 The ID of the first Chronicle.
    /// @param tokenId2 The ID of the second Chronicle.
    function dissipateEntanglement(uint256 tokenId1, uint256 tokenId2) external onlyChronicleOwner(tokenId1) onlyEntangled(tokenId1, tokenId2) {
        if (ownerOf(tokenId2) != msg.sender) revert NotChronicleOwner(); // Both must be owned by caller
        if (tokenId1 == tokenId2) revert CannotEntangleSelf(); // Should be caught by onlyEntangled usually

        Chronicle storage chronicle1 = _getChronicle(tokenId1); // Update state
        Chronicle storage chronicle2 = _getChronicle(tokenId2); // Update state

        _removeFromArray(chronicle1.entangledWith, tokenId2);
        _removeFromArray(chronicle2.entangledWith, tokenId1);

        // Optional: Add a cost or side effect for dissipation

        emit EntanglementDissipated(tokenId1, tokenId2, uint64(block.timestamp));
    }

    /// @notice Transfers Flux Energy between two entangled Chronicles owned by the caller.
    /// @param fromTokenId The Chronicle ID to transfer Flux from.
    /// @param toTokenId The Chronicle ID to transfer Flux to.
    /// @param amount The amount of Flux to transfer.
    function transferFlux(uint256 fromTokenId, uint256 toTokenId, uint256 amount) external onlyChronicleOwner(fromTokenId) onlyEntangled(fromTokenId, toTokenId) {
        if (ownerOf(toTokenId) != msg.sender) revert NotChronicleOwner(); // Both must be owned by caller
        if (fromTokenId == toTokenId) revert CannotTransferFluxToSelf();

        Chronicle storage fromChronicle = _getChronicle(fromTokenId); // Update state
        Chronicle storage toChronicle = _getChronicle(toTokenId);   // Update state

        if (fromChronicle.fluxEnergy < amount) revert InsufficientFlux();

        fromChronicle.fluxEnergy -= amount;
        toChronicle.fluxEnergy += amount;

        emit FluxTransferred(fromTokenId, toTokenId, amount, uint64(block.timestamp));
    }

    /// @notice Attempts to harmonize properties between two entangled Chronicles.
    /// @dev Example: Averages uint properties. Could have probabilistic outcomes.
    /// @param tokenId1 The ID of the first Chronicle.
    /// @param tokenId2 The ID of the second Chronicle.
    /// @param fluxToSpend The amount of Flux Energy required from *each* Chronicle.
    function harmonizeProperties(uint256 tokenId1, uint256 tokenId2, uint256 fluxToSpend) external onlyChronicleOwner(tokenId1) onlyEntangled(tokenId1, tokenId2) {
        if (ownerOf(tokenId2) != msg.sender) revert NotChronicleOwner(); // Both must be owned by caller

        Chronicle storage chronicle1 = _getChronicle(tokenId1); // Update state
        Chronicle storage chronicle2 = _getChronicle(tokenId2); // Update state

        if (chronicle1.fluxEnergy < fluxToSpend || chronicle2.fluxEnergy < fluxToSpend) revert InsufficientFlux();

        chronicle1.fluxEnergy -= fluxToSpend;
        chronicle2.fluxEnergy -= fluxToSpend;

        // --- Harmonization Logic (Example: Average uint properties) ---
        // This is complex with mappings as keys are not iterable.
        // A real implementation might require pre-defined list of harmonizable properties or different data structure.
        // For this example, let's assume we have a known property "harmony_score" uint256.
        string memory exampleKey = "harmony_score";
        uint256 score1 = chronicle1.propertiesUint[exampleKey];
        uint256 score2 = chronicle2.propertiesUint[exampleKey];

        uint256 averagedScore = (score1 + score2) / 2;

        chronicle1.propertiesUint[exampleKey] = averagedScore;
        chronicle2.propertiesUint[exampleKey] = averagedScore;

        // Could add logic for other property types (string concatenation, boolean AND/OR, etc.)
        // Could also make it probabilistic: 50% chance of averaging, 25% chance of boosting one, 25% chance of reducing both.

        emit PropertiesHarmonized(tokenId1, tokenId2, uint64(block.timestamp));
        emit ChroniclePropertyChanged(tokenId1, exampleKey, uint64(block.timestamp));
        emit ChroniclePropertyChanged(tokenId2, exampleKey, uint64(block.timestamp));
    }

    // --- Snapshot Functions ---

    /// @notice Captures the current state of a Chronicle as a Snapshot.
    /// @dev Captures key resource values and a subset of properties.
    /// @param tokenId The ID of the Chronicle to snapshot.
    function captureTemporalSnapshot(uint256 tokenId) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first

        _snapshotIdCounter.increment();
        uint256 snapshotId = _snapshotIdCounter.current();

        Snapshot storage newSnapshot = _snapshots[snapshotId];
        newSnapshot.fluxEnergy = chronicle.fluxEnergy;
        newSnapshot.temporalStability = chronicle.temporalStability;
        newSnapshot.dimensionalAnchor = chronicle.dimensionalAnchor;
        newSnapshot.timestamp = uint64(block.timestamp);

        // Store a SUBSET of properties in the snapshot.
        // Storing all mappings is not feasible directly in Solidity.
        // Example: Store a specific known uint property like "power_level".
        string memory snapshotKeyUint = "power_level";
        newSnapshot.propertiesUintSubset[snapshotKeyUint] = chronicle.propertiesUint[snapshotKeyUint];
        // Add logic here to store other specific keys needed for snapshots

        chronicle.snapshotIds.push(snapshotId);

        emit SnapshotCaptured(tokenId, snapshotId, uint64(block.timestamp));
    }

    /// @notice Restores a Chronicle's state to a previously captured Snapshot.
    /// @dev Consumes Flux and Anchor. The restoration might be imperfect or costly.
    /// @param tokenId The ID of the Chronicle to restore.
    /// @param snapshotId The ID of the Snapshot to restore from.
    /// @param fluxToSpend The amount of Flux Energy to consume.
    /// @param anchorToSpend The amount of Dimensional Anchor to consume.
    function restoreFromSnapshot(uint256 tokenId, uint256 snapshotId, uint256 fluxToSpend, uint256 anchorToSpend) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first

        if (chronicle.fluxEnergy < fluxToSpend) revert InsufficientFlux();
        if (chronicle.dimensionalAnchor < anchorToSpend) revert InsufficientAnchor();

        Snapshot storage snapshot = _snapshots[snapshotId];
        // Verify snapshot belongs to this chronicle (optional but good practice)
        bool found = false;
        for (uint i = 0; i < chronicle.snapshotIds.length; i++) {
            if (chronicle.snapshotIds[i] == snapshotId) {
                found = true;
                break;
            }
        }
        if (!found) revert InvalidSnapshotId();


        chronicle.fluxEnergy -= fluxToSpend;
        chronicle.dimensionalAnchor -= anchorToSpend;

        // --- Restore Logic ---
        // Restore key resources directly from snapshot
        chronicle.fluxEnergy = snapshot.fluxEnergy; // Note: This overwrites the result of flux spending.
        // A better design might apply the snapshot difference or apply a cost *before* restoration.
        // Let's apply the cost *after* applying snapshot values for simplicity here, assuming the cost is for the *process*.
        chronicle.temporalStability = snapshot.temporalStability;
        chronicle.dimensionalAnchor = snapshot.dimensionalAnchor;

        // Restore subset of properties from snapshot
        string memory snapshotKeyUint = "power_level";
        chronicle.propertiesUint[snapshotKeyUint] = snapshot.propertiesUintSubset[snapshotKeyUint];
        // Restore other specific snapshot properties here

        // Note: Restoration could have side effects (e.g., reset lastStateUpdateTimestamp differently,
        // add a temporary buff/debuff, remove newer snapshots).

        chronicle.lastStateUpdateTimestamp = uint64(block.timestamp); // State is now current as of restoration

        emit StateRestoredFromSnapshot(tokenId, snapshotId, uint64(block.timestamp));
    }

    // --- Temporal Anomaly Functions ---

    /// @notice Registers a new Temporal Anomaly event. Callable only by the Oracle address.
    /// @param description A string describing the anomaly.
    /// @param magnitude The intensity of the anomaly's impact.
    /// @param data Optional additional data related to the anomaly.
    function registerTemporalAnomaly(string calldata description, uint256 magnitude, bytes calldata data) external onlyOracle {
        if (_anomaliesPaused) revert AnomaliesPaused();

        _anomalyHistory.push(TemporalAnomaly({
            description: description,
            timestamp: uint64(block.timestamp),
            magnitude: magnitude,
            data: data
        }));

        _lastAnomalyTimestamp = uint64(block.timestamp);

        emit TemporalAnomalyRegistered(_anomalyHistory.length - 1, uint64(block.timestamp), description);
    }

    /// @notice Processes the impact of recent Temporal Anomalies on all Chronicles.
    /// @dev This function iterates through all tokens and applies anomaly effects.
    ///      Can be gas-intensive if many tokens exist. Callable by Oracle or Owner.
    function processAnomalyImpact() external onlyOwnerOrOracle {
         if (_anomaliesPaused) revert AnomaliesPaused();

         // Note: Iterating over all tokens can hit block gas limits.
         // In a real dApp, consider processing in batches or using a pull model
         // where anomaly impact is calculated per-chronicle when accessed/updated.
         // The current implementation updates state when _getChronicle is called,
         // so this function could potentially be used for a global sync, but
         // relying on _getChronicle might be more gas efficient for individual interactions.
         // Let's keep the iteration here to fulfill the function's purpose, but acknowledge the limit.

         uint256 totalTokens = totalSupply(); // From ERC721Enumerable
         for (uint i = 0; i < totalTokens; i++) {
             uint256 tokenId = tokenByIndex(i); // From ERC721Enumerable
             _calculateAndUpdateChronicleState(tokenId); // This will trigger _applyAnomalyImpact internally
         }

        emit AnomalyImpactProcessed(uint64(block.timestamp));
    }


    // --- Dynamic Property Management Functions ---
    // Note: Using mappings for properties is flexible but makes listing keys difficult/gas-intensive.
    // A real implementation might track keys in a separate array if listing is critical.

    /// @notice Adds or updates a uint256 property for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    /// @param value The uint256 value.
    function addChroniclePropertyUint(uint256 tokenId, string calldata key, uint256 value) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first
        chronicle.propertiesUint[key] = value;
        emit ChroniclePropertyChanged(tokenId, key, uint64(block.timestamp));
    }

    /// @notice Adds or updates a string property for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    /// @param value The string value.
    function addChroniclePropertyString(uint256 tokenId, string calldata key, string calldata value) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first
        chronicle.propertiesString[key] = value;
        emit ChroniclePropertyChanged(tokenId, key, uint64(block.timestamp));
    }

    /// @notice Adds or updates a boolean property for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    /// @param value The boolean value.
    function addChroniclePropertyBool(uint256 tokenId, string calldata key, bool value) external onlyChronicleOwner(tokenId) {
        Chronicle storage chronicle = _getChronicle(tokenId); // Update state first
        chronicle.propertiesBool[key] = value;
        emit ChroniclePropertyChanged(tokenId, key, uint64(block.timestamp));
    }

    /// @notice Removes a uint256 property from a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    function removeChroniclePropertyUint(uint256 tokenId, string calldata key) external onlyChronicleOwner(tokenId) {
         Chronicle storage chronicle = _getChronicle(tokenId); // Update state first
         delete chronicle.propertiesUint[key];
         emit ChroniclePropertyChanged(tokenId, key, uint64(block.timestamp));
    }

    /// @notice Removes a string property from a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    function removeChroniclePropertyString(uint256 tokenId, string calldata key) external onlyChronicleOwner(tokenId) {
         Chronicle storage chronicle = _getChronicle(tokenId); // Update state first
         delete chronicle.propertiesString[key];
         emit ChroniclePropertyChanged(tokenId, key, uint64(block.timestamp));
    }

    /// @notice Removes a boolean property from a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    function removeChroniclePropertyBool(uint256 tokenId, string calldata key) external onlyChronicleOwner(tokenId) {
         Chronicle storage chronicle = _getChronicle(tokenId); // Update state first
         delete chronicle.propertiesBool[key];
         emit ChroniclePropertyChanged(tokenId, key, uint66(block.timestamp)); // Fix typo in event emit
    }


    // --- Query/View Functions ---

    /// @notice Gets the current calculated Flux Energy for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @return The current Flux Energy.
    function getFluxEnergy(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Note: View functions cannot call non-view internal functions like _calculateAndUpdateChronicleState.
        // The returned value is based on the *last updated* state and time elapsed *since* that update.
        // For a truly 'current' value in a view, one would need to replicate the calculation logic here,
        // or rely on the owner/oracle calling `updateChronicleState`.
        // Let's calculate elapsed time and add accruing flux for the view.
        Chronicle storage chronicle = _chronicles[tokenId];
        uint64 timeElapsed = uint64(block.timestamp) - chronicle.lastStateUpdateTimestamp;
        return chronicle.fluxEnergy + (_baseFluxRate * timeElapsed);
    }

     /// @notice Gets the current calculated Temporal Stability for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @return The current Temporal Stability.
    function getTemporalStability(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Chronicle storage chronicle = _chronicles[tokenId];
         // For view, calculate decay since last update
        uint64 timeElapsed = uint64(block.timestamp) - chronicle.lastStateUpdateTimestamp;
        uint256 stabilityDecay = (chronicle.temporalStability * timeElapsed) / 1000;
        if (stabilityDecay >= chronicle.temporalStability) {
             return 0;
        } else {
             return chronicle.temporalStability - stabilityDecay;
        }
    }

    /// @notice Gets the current calculated Dimensional Anchor for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @return The current Dimensional Anchor.
    function getDimensionalAnchor(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Anchor doesn't accrue, only spent. Return last updated value.
        Chronicle storage chronicle = _chronicles[tokenId];
        return chronicle.dimensionalAnchor;
    }

    /// @notice Gets a specific uint256 property of a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    /// @return The uint256 value. Returns 0 if not found.
    function getChroniclePropertiesUint(uint256 tokenId, string calldata key) external view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Chronicle storage chronicle = _chronicles[tokenId];
        return chronicle.propertiesUint[key]; // Mappings return 0/false/"" for non-existent keys
    }

    /// @notice Gets a specific string property of a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    /// @return The string value. Returns "" if not found.
    function getChroniclePropertiesString(uint256 tokenId, string calldata key) external view returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Chronicle storage chronicle = _chronicles[tokenId];
        return chronicle.propertiesString[key];
    }

    /// @notice Gets a specific boolean property of a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @param key The key name for the property.
    /// @return The boolean value. Returns false if not found.
    function getChroniclePropertiesBool(uint256 tokenId, string calldata key) external view returns (bool) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Chronicle storage chronicle = _chronicles[tokenId];
        return chronicle.propertiesBool[key];
    }

     /// @notice Gets the list of Chronicles this Chronicle is entangled with.
    /// @param tokenId The Chronicle ID.
    /// @return An array of token IDs.
    function getEntangledChronicles(uint256 tokenId) external view returns (uint256[] memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         Chronicle storage chronicle = _chronicles[tokenId];
         return chronicle.entangledWith;
    }

    /// @notice Gets a range of recent Temporal Anomaly history.
    /// @param startIndex The starting index (0-based).
    /// @param endIndex The ending index (inclusive).
    /// @return An array of TemporalAnomaly structs.
    function getAnomalyHistory(uint256 startIndex, uint256 endIndex) external view returns (TemporalAnomaly[] memory) {
         uint256 historySize = _anomalyHistory.length;
         if (startIndex >= historySize || endIndex >= historySize || startIndex > endIndex) revert InvalidAnomalyIndexRange();

         uint256 count = endIndex - startIndex + 1;
         TemporalAnomaly[] memory result = new TemporalAnomaly[](count);
         for (uint i = 0; i < count; i++) {
             result[i] = _anomalyHistory[startIndex + i];
         }
         return result;
    }

    /// @notice Gets the creation timestamp of a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @return The creation timestamp (uint64).
    function getChronicleCreationTime(uint256 tokenId) external view returns (uint64) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Chronicle storage chronicle = _chronicles[tokenId];
        return chronicle.creationTimestamp;
    }

    /// @notice Gets the time elapsed since the last registered Temporal Anomaly.
    /// @return Time elapsed in seconds.
    function getTimeSinceLastAnomaly() external view returns (uint256) {
        // Assumes _lastAnomalyTimestamp is always updated when an anomaly is registered
        return block.timestamp - _lastAnomalyTimestamp;
    }

    /// @notice Calculates the estimated Flux Energy after a given time delta.
    /// @param tokenId The Chronicle ID.
    /// @param timeDelta The time in seconds to project into the future.
    /// @return The estimated Flux Energy.
    function calculatePredictedFlux(uint256 tokenId, uint256 timeDelta) external view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         Chronicle storage chronicle = _chronicles[tokenId];
         // Simple prediction based on current state and time delta.
         // Does NOT account for future anomalies, entanglement changes, or state decay effects.
         uint256 currentFlux = getFluxEnergy(tokenId); // Use the view getter to get flux including time since last update
         uint256 predictedFlux = currentFlux + (_baseFluxRate * timeDelta);
         // Simplified: Doesn't factor in entanglement effects in prediction view
         return predictedFlux;
    }

    /// @notice Gets the number of snapshots saved for a Chronicle.
    /// @param tokenId The Chronicle ID.
    /// @return The snapshot count.
    function getSnapshotCount(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Chronicle storage chronicle = _chronicles[tokenId];
        return chronicle.snapshotIds.length;
    }

    /// @notice Gets data for a specific snapshot.
    /// @param snapshotId The ID of the snapshot.
    /// @return Snapshot data.
    function getSnapshotData(uint256 snapshotId) external view returns (Snapshot memory) {
        // Note: Can't return mappings directly from view functions.
        // Need to manually retrieve required fields or define a helper struct.
        // Let's define a simplified view-friendly struct.
        struct SnapshotView {
            uint256 fluxEnergy;
            uint256 temporalStability;
            uint256 dimensionalAnchor;
            uint64 timestamp;
            // Add specific properties retrieved individually
            uint256 powerLevelSubset; // Example: assuming "power_level" is snapshotted
        }

        if (snapshotId == 0 || snapshotId > _snapshotIdCounter.current()) revert InvalidSnapshotId(); // Basic validity check

        Snapshot storage snapshot = _snapshots[snapshotId];
        SnapshotView memory viewData;
        viewData.fluxEnergy = snapshot.fluxEnergy;
        viewData.temporalStability = snapshot.temporalStability;
        viewData.dimensionalAnchor = snapshot.dimensionalAnchor;
        viewData.timestamp = snapshot.timestamp;
        // Retrieve specific subset property
        viewData.powerLevelSubset = snapshot.propertiesUintSubset["power_level"]; // Example

        return viewData;
    }


    // --- Admin Functions ---

    /// @notice Sets the address allowed to register Temporal Anomalies.
    /// @param oracle_ The new oracle address.
    function setOracleAddress(address oracle_) external onlyOwner {
        _oracleAddress = oracle_;
    }

    /// @notice Pauses or unpauses the processing of Temporal Anomalies.
    /// @param _paused True to pause, false to unpause.
    function pauseAnomalies(bool _paused) external onlyOwner {
        _anomaliesPaused = _paused;
    }

    /// @notice Sets the base rate at which Flux Energy accrues.
    /// @param rate The new base flux rate per unit time.
    function setBaseFluxRate(uint256 rate) external onlyOwner {
        _baseFluxRate = rate;
    }

    // The standard ERC721Enumerable functions (totalSupply, tokenOfOwnerByIndex, tokenByIndex)
    // are available due to inheritance and the _beforeTokenTransfer override in OpenZeppelin.
    // No need to explicitly write them here.
}
```