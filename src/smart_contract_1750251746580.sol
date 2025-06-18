Okay, here is a smart contract concept called "QuantumCanvas". It's a multi-dimensional, interactive canvas where pixels aren't static but can be affected by 'quantum' phenomena like temporal drift, state collapse, entanglement between regions, harmonic resonance, and even probabilistic quantum tunneling. It focuses on complex state interactions and on-chain simulation-like behavior rather than standard tokenomics or DeFi patterns.

It uses mappings for dynamic structures, incorporates time-based logic, uses hashing for region identification, and includes various interaction methods beyond simple state setting.

**Important Considerations & Limitations:**

1.  **Gas Costs:** Iterating over significant portions of the canvas (especially in `applyBrush` or `collapseState` if the brush/effect size is large) will be extremely expensive. This contract is more of a conceptual exploration than a production-ready system for a massive canvas. Realistic implementations would need more gas-efficient state updates (e.g., focusing effects on single points or small regions) or off-chain computation with on-chain verification.
2.  **True Randomness:** The contract uses `block.timestamp` and an internal `entropyPool` for variations. This is **not cryptographically secure randomness** and can be influenced by miners.
3.  **Complexity:** Some "quantum" effects are simplified representations due to Solidity limitations and gas costs.
4.  **Scalability:** Storing a large multi-dimensional array directly on-chain is very costly. The current mapping-based approach is better but still scales with interaction density.
5.  **Brush/Effect Logic:** The actual implementation of different `effectType`s for brushes and observers is a placeholder (`// TODO: Implement different effect types`). This would need detailed logic based on the desired effects.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. State Variables: Define canvas dimensions, pixel data structure, interaction times, quantum parameters, brush/observer configs, region ownership, entropy pool.
// 2. Structs: Define structures for Brush, ObserverEffect, TemporalDriftConfig.
// 3. Events: Signal key actions like updates, collapse, entanglement, drift, etc.
// 4. Modifiers: Control access (owner) and validate region coordinates.
// 5. Internal Helpers: Functions for bounds checking, coordinate hashing, pixel access, applying effects, triggering quantum phenomena.
// 6. Public/External Functions:
//    - Initialization & Configuration (Constructor, setTemporalDriftConfig, registerBrush, registerObserverEffect)
//    - Core Interactions (applyBrush, collapseState)
//    - Quantum/Complex Mechanics (entangleRegions, unentangleRegions, triggerTemporalDrift, increaseEntropyPool, setRegionStabilityScore)
//    - Ownership & Permissions (transferRegionOwnership)
//    - Querying & Read Functions (queryPixel, queryRegion, getCanvasDimensions, getBrushDetails, getObserverEffectDetails, getEntanglementsForRegion, getRegionHash, getRegionOwner, getRegionStabilityScore, checkHarmonicResonance, getRegionLastInteractionTime)
//    - Utility (withdrawBalance, receive)

// Function Summary:
// constructor(uint256 _width, uint256 _height, uint256 _layers): Initializes the canvas with specified dimensions. Sets deployer as owner.
// setTemporalDriftConfig(uint256 _interval, uint32 _amount): Owner sets parameters for how pixels change over time if inactive.
// registerBrush(string memory name, int256 sizeX, int256 sizeY, int256 sizeZ, uint32[] memory shape, uint32 intensity, uint32 spread, uint32 effectType): Owner defines a new brush type with shape, intensity, and effect logic.
// registerObserverEffect(string memory name, uint32 collapseIntensity, uint32 effectType): Owner defines a new observer effect type for collapsing state.
// applyBrush(uint256 x, uint256 y, uint256 z, bytes32 brushId): Applies a registered brush at the specified canvas coordinates, affecting nearby pixels based on brush properties and quantum rules. Triggers related effects (entanglement, tunneling, resonance).
// collapseState(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, bytes32 effectId): Applies an observer effect to a region, potentially solidifying transient states or revealing hidden properties.
// entangleRegions(uint256 x1, uint256 y1, uint256 z1, uint256 sizeX1, uint256 sizeY1, uint256 sizeZ1, uint256 x2, uint256 y2, uint256 z2, uint256 sizeX2, uint256 sizeY2, uint256 sizeZ2): Creates a 'quantum entanglement' link between two defined regions. Actions on one may influence the other.
// unentangleRegions(bytes32 entanglementKey): Breaks an existing entanglement link identified by its key.
// triggerTemporalDrift(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Public function allowing anyone (potentially for a fee/incentive, not implemented) to check and apply temporal drift to a region if enough time has passed since its last interaction.
// increaseEntropyPool(uint256 amount): Owner adds value to the internal entropy pool used for pseudo-random elements like quantum tunneling. Can also be increased by sending ETH via receive function.
// setRegionStabilityScore(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, uint256 score): Owner sets a stability score for a region, influencing its resistance to temporal drift and quantum tunneling.
// transferRegionOwnership(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, address newOwner): Allows the current owner of a region (or contract owner if no regional owner) to transfer ownership.
// queryPixel(uint256 x, uint256 y, uint256 z): Reads the current value of a specific pixel.
// queryRegion(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Reads the values of all pixels within a defined region.
// getCanvasDimensions(): Returns the width, height, and layers of the canvas.
// getBrushDetails(bytes32 brushId): Returns the details of a registered brush.
// getObserverEffectDetails(bytes32 effectId): Returns the details of a registered observer effect.
// getEntanglementsForRegion(bytes32 regionHash): Returns a list of entanglement keys associated with a given region hash.
// getRegionHash(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Generates a unique hash for a region definition.
// getRegionOwner(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Gets the current owner of a region.
// getRegionStabilityScore(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Gets the stability score of a region.
// checkHarmonicResonance(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Checks if the current state of a region matches a predefined (or internally calculated) harmonic pattern. Placeholder logic.
// getRegionLastInteractionTime(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ): Gets the timestamp of the last interaction within a region.
// withdrawBalance(): Owner can withdraw any ETH sent to the contract.
// receive(): Allows receiving ETH to increase the entropy pool.

contract QuantumCanvas {

    address public owner;

    // Canvas dimensions
    uint256 private width;
    uint256 private height;
    uint256 private layers;

    // Canvas state: Mapping from coordinates hash to pixel value (uint32)
    // Represents the 'superposition' or observable state of each point
    mapping(bytes32 => uint32) private canvasState;

    // Time of last interaction for each region (hashed coordinates)
    mapping(bytes32 => uint256) private regionLastInteractionTime;

    // Quantum mechanics parameters
    struct TemporalDriftConfig {
        uint256 interval; // Time in seconds after which drift *can* be triggered
        uint32 amount;    // Amount of drift per interval (e.g., value change)
    }
    TemporalDriftConfig public temporalDriftConfig;

    mapping(bytes32 => address) public regionOwner; // Optional: Allow regions to be owned
    mapping(bytes32 => uint256) public regionStabilityScore; // Higher score resists drift/tunneling

    // Entanglement: Mapping entanglement key -> list of region hashes
    mapping(bytes32 => bytes32[]) private entangledRegions;
    // Mapping region hash -> list of entanglement keys the region is part of
    mapping(bytes32 => bytes32[]) private regionEntanglements;
    // Counter to generate unique entanglement keys
    uint256 private entanglementKeyCounter;

    // Harmonic Resonance: Mapping region hash -> last checked pattern hash
    mapping(bytes32 => uint32) private regionHarmonicPatternHash;
    uint256 private constant HARMONIC_PATTERN_THRESHOLD = 500; // Example threshold for resonance trigger

    // Quantum Tunneling: Probability parameter (e.g., 1 in QUANTUM_TUNNEL_CHANCE chance per brush application)
    uint256 private constant QUANTUM_TUNNEL_CHANCE_INV = 1000; // 1 in 1000 chance
    uint256 private entropyPool; // Accumulated "randomness" from interactions/ETH


    // Brush Configuration
    struct Brush {
        string name;
        int256 sizeX; // Signed sizes to allow brushes centered around (x,y,z)
        int256 sizeY;
        int256 sizeZ;
        uint32[] shape; // 1D array representing the 3D brush shape (sizeX*sizeY*sizeZ)
        uint32 intensity; // How strong the brush effect is
        uint32 spread;    // How much the effect fades with distance (simple model)
        uint32 effectType; // Type of effect (e.g., 1: add, 2: subtract, 3: set, 4: XOR, 5: probabilistic)
    }
    mapping(bytes32 => Brush) private registeredBrushes;
    bytes32[] public registeredBrushIds;

    // Observer Effect Configuration (for collapseState)
    struct ObserverEffect {
        string name;
        uint32 collapseIntensity; // How strongly the state collapses
        uint32 effectType;        // Type of effect (e.g., 1: average, 2: sum, 3: force value, 4: reveal hidden - requires hidden state logic not fully in this draft)
    }
    mapping(bytes32 => ObserverEffect) private registeredObserverEffects;
    bytes32[] public registeredObserverEffectIds;


    // Events
    event CanvasInitialized(uint256 width, uint256 height, uint256 layers);
    event RegionUpdated(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, address indexed by, bytes32 indexed brushId);
    event StateCollapsed(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, address indexed by, bytes32 indexed effectId);
    event RegionsEntangled(bytes32 indexed key, bytes32 regionAHash, bytes32 regionBHash);
    event RegionUnentangled(bytes32 indexed key, bytes32 regionHash);
    event TemporalDriftApplied(bytes32 indexed regionHash, uint256 timeElapsed, uint32 driftAmount);
    event HarmonicResonanceTriggered(bytes32 indexed regionHash, uint32 indexed patternHash, address indexed triggeredBy);
    event QuantumTunnelingOccurred(bytes32 indexed fromRegionHash, bytes32 indexed toCoordsHash, uint32 valueChange);
    event BrushRegistered(bytes32 indexed brushId, string name);
    event ObserverEffectRegistered(bytes32 indexed effectId, string name);
    event RegionOwned(bytes32 indexed regionHash, address indexed newOwner);
    event EntropyPoolIncreased(uint256 amount);
    event TemporalDriftConfigUpdated(uint256 interval, uint32 amount);
    event RegionStabilityScoreUpdated(bytes32 indexed regionHash, uint256 newScore);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier regionExists(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ) {
        require(_isValidRegion(x, y, z, sizeX, sizeY, sizeZ), "Invalid region coordinates or size");
        _;
    }

    modifier canInteractWithRegion(uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        address currentOwner = regionOwner[regionHash];
        // If a region owner exists, only they or the contract owner can interact
        require(currentOwner == address(0) || msg.sender == currentOwner || msg.sender == owner, "Not authorized to interact with this region");
        _;
    }

    constructor(uint256 _width, uint256 _height, uint256 _layers) {
        require(_width > 0 && _height > 0 && _layers > 0, "Canvas dimensions must be greater than 0");
        owner = msg.sender;
        width = _width;
        height = _height;
        layers = _layers;
        temporalDriftConfig = TemporalDriftConfig(0, 0); // Drift disabled by default
        entanglementKeyCounter = 1;
        entropyPool = 0; // Start with zero entropy

        emit CanvasInitialized(width, height, layers);
    }

    receive() external payable {
        increaseEntropyPool(msg.value); // Convert ETH to entropy (example)
    }

    // --- Configuration Functions (Owner Only) ---

    function setTemporalDriftConfig(uint256 _interval, uint32 _amount) external onlyOwner {
        temporalDriftConfig = TemporalDriftConfig(_interval, _amount);
        emit TemporalDriftConfigUpdated(_interval, _amount);
    }

    function registerBrush(
        string memory name,
        int256 sizeX, int256 sizeY, int256 sizeZ,
        uint32[] memory shape, // sizeX*sizeY*sizeZ elements assuming positive sizes
        uint32 intensity, uint32 spread, uint32 effectType
    ) external onlyOwner returns (bytes32 brushId) {
        require(sizeX != 0 && sizeY != 0 && sizeZ != 0, "Brush size must be non-zero");
        require(shape.length == uint256(sizeX * sizeY * sizeZ), "Shape array size mismatch");

        brushId = keccak256(abi.encodePacked(name, sizeX, sizeY, sizeZ, shape, intensity, spread, effectType));
        require(registeredBrushes[brushId].sizeX == 0, "Brush already registered"); // Check if sizeX is non-zero as a proxy

        registeredBrushes[brushId] = Brush(name, sizeX, sizeY, sizeZ, shape, intensity, spread, effectType);
        registeredBrushIds.push(brushId); // Keep track of all registered IDs
        emit BrushRegistered(brushId, name);
    }

     function registerObserverEffect(
        string memory name,
        uint32 collapseIntensity,
        uint32 effectType
    ) external onlyOwner returns (bytes32 effectId) {
        effectId = keccak256(abi.encodePacked(name, collapseIntensity, effectType));
        require(registeredObserverEffects[effectId].collapseIntensity == 0, "Observer effect already registered"); // Check proxy

        registeredObserverEffects[effectId] = ObserverEffect(name, collapseIntensity, effectType);
        registeredObserverEffectIds.push(effectId); // Keep track of all registered IDs
        emit ObserverEffectRegistered(effectId, name);
    }

    function increaseEntropyPool(uint256 amount) public onlyOwner {
        entropyPool += amount;
        emit EntropyPoolIncreased(amount);
    }

    function setRegionStabilityScore(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, uint256 score
    ) external onlyOwner regionExists(x, y, z, sizeX, sizeY, sizeZ) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        regionStabilityScore[regionHash] = score;
        emit RegionStabilityScoreUpdated(regionHash, score);
    }

    // --- Core Interaction Functions ---

    function applyBrush(uint256 x, uint256 y, uint256 z, bytes32 brushId)
        external
        canInteractWithRegion(x, y, z, 1, 1, 1) // Check permission for the target pixel's region
    {
        require(_isValidCoords(x, y, z), "Invalid pixel coordinates");
        Brush storage brush = registeredBrushes[brushId];
        require(brush.sizeX != 0, "Brush not registered");

        // Apply brush centered around (x, y, z)
        for (int256 i = 0; i < brush.sizeX; ++i) {
            for (int256 j = 0; j < brush.sizeY; ++j) {
                for (int256 k = 0; k < brush.sizeZ; ++k) {
                    uint256 targetX = uint256(int256(x) + i - brush.sizeX / 2);
                    uint256 targetY = uint256(int256(y) + j - brush.sizeY / 2);
                    uint256 targetZ = uint256(int256(z) + k - brush.sizeZ / 2);

                    if (_isValidCoords(targetX, targetY, targetZ)) {
                        uint256 shapeIndex = uint256(i * brush.sizeY * brush.sizeZ + j * brush.sizeZ + k);
                        uint32 shapeValue = brush.shape[shapeIndex];

                        // Simple distance-based spread calculation
                        uint256 distSq = uint256(i*i + j*j + k*k);
                        uint32 appliedIntensity = brush.intensity;
                        if (brush.spread > 0) {
                             // Reduce intensity based on squared distance and spread
                            appliedIntensity = appliedIntensity * 1000 / (1000 + uint32(distSq * brush.spread));
                        }


                        uint32 currentValue = _getPixel(targetX, targetY, targetZ);
                        uint32 newValue = _applyBrushEffect(currentValue, shapeValue, appliedIntensity, brush.effectType);

                        _setPixel(targetX, targetY, targetZ, newValue);

                         // --- Quantum Effects triggered per pixel application ---

                        // Temporal Drift update for the affected pixel's region
                         bytes32 pixelRegionHash = _getRegionHashForPixel(targetX, targetY, targetZ);
                        _updateRegionLastInteractionTime(pixelRegionHash);

                        // Harmonic Resonance Check (check the whole region after a pixel update)
                        // In a real contract, this might check a larger area or only certain patterns
                        if (_checkHarmonicPattern(pixelRegionHash)) {
                            emit HarmonicResonanceTriggered(pixelRegionHash, regionHarmonicPatternHash[pixelRegionHash], msg.sender);
                            // TODO: Add logic for what happens during resonance (e.g., boost stability, special effects)
                        }

                        // Quantum Tunneling Attempt
                        _triggerQuantumTunneling(targetX, targetY, targetZ, newValue);
                    }
                }
            }
        }

         // Trigger entanglement effects for all regions the original pixel (x,y,z) belongs to
         bytes32 startingRegionHash = _getRegionHashForPixel(x, y, z);
         bytes32[] memory entKeys = regionEntanglements[startingRegionHash];
         for(uint i=0; i < entKeys.length; i++) {
             _applyEntanglementEffect(entKeys[i], startingRegionHash);
         }


        // A more practical implementation would emit one event per region affected,
        // or a summary event. This is simplified.
        emit RegionUpdated(x, y, z, uint256(brush.sizeX), uint256(brush.sizeY), uint256(brush.sizeZ), msg.sender, brushId);

         // Increase entropy pool slightly with each interaction
        entropyPool = entropyPool + 1 % type(uint256).max;
    }

    function collapseState(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, bytes32 effectId
    ) external regionExists(x, y, z, sizeX, sizeY, sizeZ) canInteractWithRegion(x, y, z, sizeX, sizeY, sizeZ) {
        ObserverEffect storage effect = registeredObserverEffects[effectId];
        require(effect.collapseIntensity > 0, "Observer effect not registered");

        // This is a placeholder. A real collapse effect would
        // read the state of the region, apply the effectType logic,
        // and update the pixels.
        // TODO: Implement state collapse logic based on effect.effectType

        // Example: Simple average (not realistic for a complex system, but demonstrates iteration)
        uint256 sum = 0;
        uint256 count = 0;
         for (uint256 i = x; i < x + sizeX; ++i) {
            for (uint256 j = y; j < y + sizeY; ++j) {
                for (uint256 k = z; k < z + sizeZ; ++k) {
                     if (_isValidCoords(i, j, k)) {
                          sum += _getPixel(i, j, k);
                          count++;
                     }
                }
            }
        }
        uint32 collapsedValue = count > 0 ? uint32(sum / count) : 0;

        // Now apply the effect - e.g., force all pixels to the collapsedValue
        for (uint256 i = x; i < x + sizeX; ++i) {
            for (uint256 j = y; j < y + sizeY; ++j) {
                for (uint256 k = z; k < z + sizeZ; ++k) {
                     if (_isValidCoords(i, j, k)) {
                         _setPixel(i, j, k, _applyObserverEffect(_getPixel(i,j,k), collapsedValue, effect.collapseIntensity, effect.effectType));
                     }
                }
            }
        }


        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        _updateRegionLastInteractionTime(regionHash); // Collapse counts as interaction

        emit StateCollapsed(x, y, z, sizeX, sizeY, sizeZ, msg.sender, effectId);

         // Increase entropy pool slightly
        entropyPool = entropyPool + 1 % type(uint256).max;
    }

    // --- Quantum Mechanics Functions ---

    function entangleRegions(
        uint256 x1, uint256 y1, uint256 z1, uint256 sizeX1, uint256 sizeY1, uint256 sizeZ1,
        uint256 x2, uint256 y2, uint256 z2, uint256 sizeX2, uint256 sizeY2, uint256 sizeZ2
    ) external
     regionExists(x1, y1, z1, sizeX1, sizeY1, sizeZ1)
     regionExists(x2, y2, z2, sizeX2, sizeY2, sizeZ2)
     canInteractWithRegion(x1, y1, z1, sizeX1, sizeY1, sizeZ1) // Must have permission for BOTH regions
     canInteractWithRegion(x2, y2, z2, sizeX2, sizeY2, sizeZ2)
    returns (bytes32 entanglementKey) {
        bytes32 regionHash1 = _regionCoordsToHash(x1, y1, z1, sizeX1, sizeY1, sizeZ1);
        bytes32 regionHash2 = _regionCoordsToHash(x2, y2, z2, sizeX2, sizeY2, sizeZ2);

        require(regionHash1 != regionHash2, "Cannot entangle a region with itself");

        // Generate a unique key for this entanglement
        entanglementKey = keccak256(abi.encodePacked(entanglementKeyCounter++, regionHash1, regionHash2, block.timestamp));

        // Store the entanglement mapping
        entangledRegions[entanglementKey].push(regionHash1);
        entangledRegions[entanglementKey].push(regionHash2);

        // Store the reverse mapping (which entanglements a region is part of)
        regionEntanglements[regionHash1].push(entanglementKey);
        regionEntanglements[regionHash2].push(entanglementKey);

        emit RegionsEntangled(entanglementKey, regionHash1, regionHash2);

        // Increase entropy pool slightly
        entropyPool = entropyPool + 1 % type(uint256).max;
    }

    function unentangleRegions(bytes32 entanglementKey) external {
        bytes32[] storage regionsToUnentangle = entangledRegions[entanglementKey];
        require(regionsToUnentangle.length > 0, "Entanglement key not found");

         // Check if caller has permission for at least one region in the entanglement
         bool hasPermission = false;
         for(uint i=0; i < regionsToUnentangle.length; i++) {
             // Reconstruct coords from hash is hard. Check permission by trying a sample pixel.
             // This is a simplification. Proper region ownership would need better tracking or different permission model.
              // For now, let's just require owner permission to unentangle anything.
              if (msg.sender == owner) {
                  hasPermission = true;
                  break;
              }
         }
         require(hasPermission, "Not authorized to break this entanglement");


        for (uint i = 0; i < regionsToUnentangle.length; ++i) {
            bytes32 regionHash = regionsToUnentangle[i];

            // Remove this entanglement key from the region's list
            bytes32[] storage keysForRegion = regionEntanglements[regionHash];
            for (uint j = 0; j < keysForRegion.length; ++j) {
                if (keysForRegion[j] == entanglementKey) {
                    // Swap and pop to remove efficiently
                    keysForRegion[j] = keysForRegion[keysForRegion.length - 1];
                    keysForRegion.pop();
                    break; // Assuming entanglementKey appears only once per region's list
                }
            }

            emit RegionUnentangled(entanglementKey, regionHash);
        }

        // Clear the entanglement from the main mapping
        delete entangledRegions[entanglementKey];

         // Increase entropy pool slightly
        entropyPool = entropyPool + 1 % type(uint256).max;
    }

    function triggerTemporalDrift(
         uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) external regionExists(x, y, z, sizeX, sizeY, sizeZ) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        uint256 lastInteraction = regionLastInteractionTime[regionHash];

        if (temporalDriftConfig.interval == 0 || lastInteraction == 0) {
             // Drift is disabled or region never interacted with
             return;
        }

        uint256 timeElapsed = block.timestamp - lastInteraction;

        // Calculate potential drift applications based on interval
        uint256 potentialDrifts = timeElapsed / temporalDriftConfig.interval;

        if (potentialDrifts == 0) {
            return; // Not enough time has passed
        }

        // Apply drift up to a max number of times to avoid huge loops if interval is small
        uint256 driftsToApply = potentialDrifts > 10 ? 10 : potentialDrifts; // Cap to save gas

        // Apply drift to each pixel in the region
        for (uint256 i = x; i < x + sizeX; ++i) {
            for (uint256 j = y; j < y + sizeY; ++j) {
                for (uint256 k = z; k < z + sizeZ; ++k) {
                     if (_isValidCoords(i, j, k)) {
                         bytes32 coordsHash = _coordsToHash(i,j,k);
                         uint32 currentValue = canvasState[coordsHash];
                         uint256 stability = regionStabilityScore[regionHash]; // Use region score for pixel stability

                         // Calculate drift amount considering stability
                         // Higher stability reduces drift
                         uint32 driftAmountForPixel = temporalDriftConfig.amount;
                         if (stability > 0) {
                              // Simple reduction: drift is driftAmount / (1 + stability)
                              driftAmountForPixel = driftAmountForPixel / (1 + uint32(stability));
                         }


                         // Apply drift multiple times
                         uint33 totalDrift = 0;
                         for(uint iter = 0; iter < driftsToApply; ++iter) {
                             // Simple drift: just add/subtract based on time/entropy
                              // A more complex model would involve state-dependent changes
                             if ((entropyPool + iter) % 2 == 0) { // Pseudo-random direction
                                  totalDrift += driftAmountForPixel;
                             } else {
                                  totalDrift -= driftAmountForPixel; // Use signed math if values can go negative
                             }
                         }

                         // Apply the total drift (handle overflow/underflow if needed)
                          uint32 newValue = currentValue;
                          if (totalDrift > 0) {
                              newValue = currentValue + uint32(totalDrift) > type(uint32).max ? type(uint32).max : currentValue + uint32(totalDrift);
                          } else if (totalDrift < 0) {
                              newValue = currentValue < uint32(-int32(totalDrift)) ? 0 : currentValue - uint32(-int32(totalDrift));
                          }


                         canvasState[coordsHash] = newValue;
                     }
                }
            }
        }

        // Update last interaction time to the time *after* applying drifts
        // This prevents drift from being applied multiple times for the same time period
        regionLastInteractionTime[regionHash] = block.timestamp;

        emit TemporalDriftApplied(regionHash, timeElapsed, temporalDriftConfig.amount);

         // Increase entropy pool slightly
        entropyPool = entropyPool + 1 % type(uint256).max;
    }

     // --- Ownership Functions ---
    function transferRegionOwnership(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ, address newOwner
    ) external regionExists(x, y, z, sizeX, sizeY, sizeZ) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        address currentOwner = regionOwner[regionHash];

        // Only the current region owner or contract owner can transfer
        require(msg.sender == currentOwner || msg.sender == owner, "Not authorized to transfer ownership of this region");
        require(newOwner != address(0), "New owner cannot be the zero address");

        regionOwner[regionHash] = newOwner;
        emit RegionOwned(regionHash, newOwner);
    }


    // --- Query & Read Functions ---

    function queryPixel(uint256 x, uint256 y, uint256 z) public view returns (uint32) {
         require(_isValidCoords(x, y, z), "Invalid pixel coordinates");
         return _getPixel(x, y, z);
    }

    function queryRegion(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) public view regionExists(x, y, z, sizeX, sizeY, sizeZ) returns (uint32[] memory) {
        uint32[] memory regionData = new uint32[](sizeX * sizeY * sizeZ);
        uint256 index = 0;
        for (uint256 i = x; i < x + sizeX; ++i) {
            for (uint256 j = y; j < y + sizeY; ++j) {
                for (uint256 k = z; k < z + sizeZ; ++k) {
                    // _isValidCoords check already done by regionExists modifier
                    regionData[index] = _getPixel(i, j, k);
                    index++;
                }
            }
        }
        return regionData;
    }

    function getCanvasDimensions() public view returns (uint256 w, uint256 h, uint256 l) {
        return (width, height, layers);
    }

    function getBrushDetails(bytes32 brushId) public view returns (Brush memory) {
        require(registeredBrushes[brushId].sizeX != 0, "Brush not registered");
        return registeredBrushes[brushId];
    }

     function getObserverEffectDetails(bytes32 effectId) public view returns (ObserverEffect memory) {
         require(registeredObserverEffects[effectId].collapseIntensity > 0, "Observer effect not registered");
         return registeredObserverEffects[effectId];
     }

     function getEntanglementsForRegion(bytes32 regionHash) public view returns (bytes32[] memory) {
         return regionEntanglements[regionHash];
     }

     function getRegionHash(
         uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
     ) public pure returns (bytes32) {
         return _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
     }

    function getRegionOwner(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) public view regionExists(x, y, z, sizeX, sizeY, sizeZ) returns (address) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        return regionOwner[regionHash];
    }

     function getRegionStabilityScore(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) public view regionExists(x, y, z, sizeX, sizeY, sizeZ) returns (uint256) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        return regionStabilityScore[regionHash];
    }

    function checkHarmonicResonance(
         uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) public view regionExists(x, y, z, sizeX, sizeY, sizeZ) returns (bool isResonating, uint32 currentPatternHash) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        currentPatternHash = _calculateHarmonicPatternHash(x, y, z, sizeX, sizeY, sizeZ); // Placeholder

        // Example check: Does the current pattern hash exceed a threshold?
        isResonating = currentPatternHash > HARMONIC_PATTERN_THRESHOLD;

        return (isResonating, currentPatternHash);
    }

    function getRegionLastInteractionTime(
         uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) public view regionExists(x, y, z, sizeX, sizeY, sizeZ) returns (uint256) {
        bytes32 regionHash = _regionCoordsToHash(x, y, z, sizeX, sizeY, sizeZ);
        return regionLastInteractionTime[regionHash];
    }


     // --- Utility Functions ---

     function withdrawBalance() external onlyOwner {
         (bool success, ) = owner.call{value: address(this).balance}("");
         require(success, "Withdrawal failed");
     }


    // --- Internal Helper Functions ---

    function _isValidCoords(uint256 x, uint256 y, uint256 z) internal view returns (bool) {
        return x < width && y < height && z < layers;
    }

    function _isValidRegion(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) internal view returns (bool) {
        return x < width && y < height && z < layers &&
               x + sizeX <= width && y + sizeY <= height && z + sizeZ <= layers &&
               sizeX > 0 && sizeY > 0 && sizeZ > 0;
    }

    function _coordsToHash(uint256 x, uint256 y, uint256 z) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, z));
    }

    function _regionCoordsToHash(
        uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, z, sizeX, sizeY, sizeZ));
    }

     // Helper to get the default region hash for a single pixel's location
     // Useful for applying region-based logic like temporal drift to single pixels
     function _getRegionHashForPixel(uint256 x, uint256 y, uint256 z) internal pure returns (bytes32) {
         // Define a default smallest region size, e.g., 1x1x1 pixel region
         return _regionCoordsToHash(x, y, z, 1, 1, 1);
     }


    function _getPixel(uint256 x, uint256 y, uint256 z) internal view returns (uint32) {
        // No bounds check needed here, assumes caller used _isValidCoords or modifier
        bytes32 coordsHash = _coordsToHash(x, y, z);
        return canvasState[coordsHash];
    }

    function _setPixel(uint256 x, uint256 y, uint256 z, uint32 value) internal {
         // No bounds check needed here
        bytes32 coordsHash = _coordsToHash(x, y, z);
        canvasState[coordsHash] = value;

        // Update interaction time for the pixel's default region
        bytes32 pixelRegionHash = _getRegionHashForPixel(x, y, z);
        _updateRegionLastInteractionTime(pixelRegionHash);
    }

    function _updateRegionLastInteractionTime(bytes32 regionHash) internal {
        regionLastInteractionTime[regionHash] = block.timestamp;
    }

    function _applyBrushEffect(uint32 currentValue, uint32 shapeValue, uint32 intensity, uint32 effectType) internal pure returns (uint32) {
        // TODO: Implement different effect types based on `effectType`
        // This is a simplified example:
        if (effectType == 1) { // Add
             // Handle overflow
            return currentValue + shapeValue + intensity > type(uint32).max ? type(uint32).max : currentValue + shapeValue + intensity;
        } else if (effectType == 2) { // Subtract
             // Handle underflow
            uint32 subtractAmount = shapeValue + intensity;
            return currentValue < subtractAmount ? 0 : currentValue - subtractAmount;
        } else if (effectType == 3) { // Set
            return shapeValue; // Intensity could modify this, e.g., set to value * intensity / max_intensity
        } else if (effectType == 4) { // XOR
             return currentValue ^ shapeValue ^ intensity;
        } else if (effectType == 5) { // Probabilistic Add/Subtract based on shape value and intensity
             // Simple pseudo-random choice influenced by input values
             if ((currentValue + shapeValue + intensity) % 2 == 0) {
                 return currentValue + intensity > type(uint32).max ? type(uint32).max : currentValue + intensity;
             } else {
                 return currentValue < intensity ? 0 : currentValue - intensity;
             }
        } else {
            return currentValue; // Default: no change
        }
    }

    function _applyObserverEffect(uint32 currentValue, uint32 regionCollapsedValue, uint32 collapseIntensity, uint32 effectType) internal pure returns (uint32) {
         // TODO: Implement different effect types based on `effectType`
         // This is a simplified example:
         if (effectType == 1) { // Move towards average/collapsed value
             if (currentValue > regionCollapsedValue) {
                 uint32 diff = currentValue - regionCollapsedValue;
                 return currentValue < diff / collapseIntensity ? 0 : currentValue - diff / collapseIntensity; // Simple movement
             } else {
                 uint32 diff = regionCollapsedValue - currentValue;
                 return currentValue + diff / collapseIntensity > type(uint32).max ? type(uint32).max : currentValue + diff / collapseIntensity;
             }
         } else if (effectType == 3) { // Force to collapsed value
             return regionCollapsedValue;
         } else {
             return currentValue; // Default: no change
         }
         // Effect type 4 "reveal hidden state" would require a separate mapping for hidden state
    }


    function _applyEntanglementEffect(bytes32 entanglementKey, bytes32 triggeredRegionHash) internal {
        bytes32[] storage entangled = entangledRegions[entanglementKey];
        if (entangled.length < 2) return; // Not a valid entanglement

        bytes32 otherRegionHash;
        if (entangled[0] == triggeredRegionHash) {
            otherRegionHash = entangled[1];
        } else if (entangled[1] == triggeredRegionHash) {
            otherRegionHash = entangled[0];
        } else {
             // Triggered region is not part of this entanglement
             return;
        }

        // TODO: Implement entanglement effect logic.
        // This is highly conceptual. What does entanglement mean on-chain?
        // - Copying state? (Expensive)
        // - Applying a smaller, mirrored brush effect?
        // - Linking their stability scores or drift rates?
        // - Triggering a collapse in the other region?
        // - Sharing entropy?

        // Simple example: If triggered region's average state is high, slightly boost the other region's central pixel
        // This would require reading the region state (expensive).
        // Let's do something simpler: a small, state-dependent "nudge" on the other region's "representative" pixel (e.g., top-left)

        // Placeholder: Find representative coordinates for the other region hash (impossible from hash alone!)
        // A real implementation would need to store region coordinates mapping to hash, or hash -> coords.
        // For this example, we'll skip the actual state change and just emit an event.
        // Emitting event using the other region's hash as identifier
        emit RegionUpdated(0,0,0,0,0,0, address(this), bytes32(uint256(otherRegionHash))); // Use address(this) for internal triggers

        // A more realistic model would be to apply a simplified brush effect
        // centered at the other region's origin (if we could get the coords).
        // Or link state variables like stability or drift for the two regions.

        // Increase entropy pool slightly
        entropyPool = entropyPool + 1 % type(uint256).max;
    }

    function _checkHarmonicPattern(bytes32 regionHash) internal returns (bool) {
         // TODO: Implement complex pattern recognition logic.
         // This is extremely difficult and gas-intensive on-chain.
         // Could be simplified to:
         // 1. Calculate a simple checksum/hash of the region's pixel values.
         // 2. Compare against a predefined list of "harmonic" hashes.
         // 3. Or check if the checksum/hash meets a certain threshold based on region size/value.

         // Placeholder: Calculate a simple XOR sum of the region's pixels
         // This requires iterating the region (expensive)
         // For now, let's just return a pseudo-random bool based on region hash and entropy
         uint32 patternHash = uint32(uint256(keccak256(abi.encodePacked(regionHash, entropyPool))) % 1000); // Pseudo-hash

         regionHarmonicPatternHash[regionHash] = patternHash; // Store for querying

         return patternHash > HARMONIC_PATTERN_THRESHOLD;
    }


    function _triggerQuantumTunneling(uint256 x, uint256 y, uint256 z, uint32 valueChange) internal {
        // Pseudo-random check based on current state and entropy
        // Using block.timestamp is exploitable, but needed for variation in a simplified model
        uint265 randomFactor = uint256(keccak256(abi.encodePacked(x, y, z, block.timestamp, entropyPool)));

        if (QUANTUM_TUNNEL_CHANCE_INV > 0 && randomFactor % QUANTUM_TUNNEL_CHANCE_INV == 0) {
             // Tunneling occurs! Find a target location.
             // This should select a location randomly within bounds, potentially weighted by stability or distance.
             // Simple example: Use entropy to pick target coords (still pseudo-random)
             uint256 targetX = (randomFactor / QUANTUM_TUNNEL_CHANCE_INV) % width;
             uint256 targetY = (randomFactor / (QUANTUM_TUNNEL_CHANCE_INV * width)) % height;
             uint256 targetZ = (randomFactor / (QUANTUM_TUNNEL_CHANCE_INV * width * height)) % layers;

             // Ensure target is different from origin
             if (targetX == x && targetY == y && targetZ == z) {
                 if (width > 1) targetX = (targetX + 1) % width;
                 else if (height > 1) targetY = (targetY + 1) % height;
                 else if (layers > 1) targetZ = (targetZ + 1) % layers;
                 else return; // Only one pixel, no tunneling possible
             }

             // Apply a small effect at the target location (e.g., transfer some value change)
             bytes32 targetCoordsHash = _coordsToHash(targetX, targetY, targetZ);
             uint32 currentValue = canvasState[targetCoordsHash];

             // Apply a small fraction of the original value change
             uint32 tunneledValueChange = valueChange / 10 > 0 ? valueChange / 10 : 1; // Tunnel at least 1

             // Simple addition/subtraction for tunneling effect
              uint33 newTargetValue = uint33(currentValue) + tunneledValueChange;
              // Handle overflow/underflow based on original change direction or other logic
              // For simplicity, just add here
              canvasState[targetCoordsHash] = uint33(newTargetValue) > type(uint32).max ? type(uint32).max : uint32(newTargetValue);


             emit QuantumTunnelingOccurred(_getRegionHashForPixel(x,y,z), targetCoordsHash, tunneledValueChange);

             // Decrease entropy pool slightly as randomness is 'used'
             entropyPool = entropyPool > 0 ? entropyPool - 1 : 0;
        }
    }

    // Placeholder for actual harmonic pattern calculation (expensive)
    function _calculateHarmonicPatternHash(
         uint256 x, uint256 y, uint256 z, uint256 sizeX, uint256 sizeY, uint256 sizeZ
    ) internal view returns (uint32) {
         // This would involve reading pixel data and performing calculations (e.g., sum, XOR, Fourier-like analysis, checking specific patterns)
         // Example: Simple sum of pixel values in the region (very basic pattern detection)
         uint256 sum = 0;
         for (uint256 i = x; i < x + sizeX; ++i) {
            for (uint256 j = y; j < y + sizeY; ++j) {
                for (uint256 k = z; k < z + sizeZ; ++k) {
                     if (_isValidCoords(i, j, k)) { // Re-check just in case
                         sum += _getPixel(i, j, k);
                     }
                }
            }
        }
        // Use part of the sum as a pseudo-hash
        return uint32(sum % type(uint32).max);
    }
}
```