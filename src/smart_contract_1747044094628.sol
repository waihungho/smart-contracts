Okay, here is a Solidity smart contract concept called `DimensionalCanvas`. It's a 3D interactive art space where users can place and own "Element" NFTs. Elements have properties like color, type, and energy, which decay over time. Adjacent elements can interact in complex ways. Users can reinforce their elements, and specific states of the canvas can be captured as "Scene" NFTs.

This contract combines concepts of:
1.  **3D Spatial Mapping:** Using nested mappings with `int256` for coordinates.
2.  **Dynamic NFTs:** Element NFTs have properties that change based on time (decay) and interactions. Metadata (`tokenURI`) would reflect this state.
3.  **Interactive Art/Game Mechanics:** Elements interact based on predefined rules (`triggerInteractionCheck`).
4.  **Decay and Reinforcement:** Elements lose energy and can be reinforced by their owners.
5.  **Snapshot NFTs:** Ability to capture specific moments in the canvas history as separate NFTs.
6.  **Element Types:** Different types of elements with unique properties and interaction rules.

It aims to be creative by moving beyond simple 2D grid or standard ERC721 PFP concepts into a dynamic, evolving 3D space.

---

## Smart Contract: DimensionalCanvas

A generative, interactive 3D canvas where users place dynamic element NFTs.

### Outline:

1.  **License and Pragma**
2.  **Imports:** ERC721, Ownable, ReentrancyGuard
3.  **Error Definitions**
4.  **Structs:**
    *   `Coord`: Represents a 3D coordinate (x, y, z).
    *   `ElementState`: Represents the state of an element at a coordinate.
    *   `ElementTypeConfig`: Configuration for different types of elements.
    *   `CanvasConfig`: Global configuration for the canvas.
    *   `SceneDetails`: Details for a captured scene snapshot.
5.  **Events:**
    *   `ElementPlaced`: When a new element is placed.
    *   `ElementReinforced`: When an element's energy is increased.
    *   `ElementDecayed`: When an element loses energy.
    *   `ElementRemoved`: When an element is removed (burned).
    *   `InteractionTriggered`: When an interaction occurs between elements.
    *   `SceneSnapshotCreated`: When a scene NFT is minted.
    *   `ElementTypeAdded`: When a new element type is defined.
    *   `CanvasConfigUpdated`: When global canvas parameters change.
    *   `Paused`: When the contract is paused.
    *   `Unpaused`: When the contract is unpaused.
6.  **State Variables:**
    *   `space`: 3D mapping storing `ElementState`.
    *   `elementTokenIdMap`: Map from coordinates to Element NFT token ID.
    *   `elementCoordMap`: Map from Element NFT token ID to coordinates.
    *   `elementNFTCounter`: Counter for Element NFT token IDs.
    *   `isSceneNFT`: Map to differentiate Element/Scene NFT token IDs.
    *   `sceneNFTCounter`: Counter for Scene NFT token IDs (used internally for IDs).
    *   `sceneNFTDetails`: Map from Scene NFT token ID to its details.
    *   `elementTypes`: Map from index to `ElementTypeConfig`.
    *   `elementTypeCount`: Counter for element types.
    *   `canvasConfig`: Global configuration struct.
7.  **Constructor:** Initializes ERC721, Owner, adds default element types, sets initial config.
8.  **Modifiers:** `onlyElementOwner`, `onlyExistingElement`, `whenNotPaused`.
9.  **Core Canvas Interaction Functions:**
    *   `placeElement`
    *   `reinforceElement`
    *   `triggerInteractionCheck`
10. **Element State & NFT Functions:**
    *   `getElementState`
    *   `getElementNFTId`
    *   `getCoordinatesByTokenId`
    *   `getElementOwner` (ERC721 override helper)
    *   `decayElement` (publicly callable for gas efficiency)
    *   `removeElement` (internal)
    *   `cleanupDecayedElements` (batch decay check)
    *   `burnElement` (owner burns their NFT)
    *   `getElementEnergy`
    *   `getTimeSincePlacement`
    *   `getDecayStatus`
11. **Spatial Query Functions:**
    *   `isOccupied`
    *   `getNeighbors`
    *   `isCoordValid`
12. **Element Type Management Functions:**
    *   `addElementType`
    *   `updateElementTypeParams`
    *   `getElementTypeDetails`
    *   `getElementTypeCount`
13. **Canvas Configuration Functions:**
    *   `getCanvasConfig`
    *   `setCanvasBounds`
    *   `getCanvasBounds`
    *   `setCanvasPlacementCostMultiplier`
    *   `setCanvasReinforceCostMultiplier`
14. **Scene Snapshot Functions:**
    *   `createSceneSnapshot`
    *   `getSceneDetails`
    *   `getTotalScenes`
15. **ERC721 Standard Overrides & Helpers:**
    *   `tokenURI`
    *   `supportsInterface`
16. **Admin & Utility Functions:**
    *   `withdrawFunds`
    *   `setPaused`
    *   `getTotalElements`

### Function Summary:

1.  `constructor`: Initializes contract, sets owner, adds initial element types and config.
2.  `placeElement(int256 x, int256 y, int256 z, uint256 elementTypeIndex, string memory color)`: Allows a user to place a new element at specific coordinates, minting an Element NFT. Requires payment based on config and element type.
3.  `reinforceElement(int256 x, int256 y, int256 z)`: Allows the owner of an element to increase its energy, resetting its decay timer. Requires payment.
4.  `triggerInteractionCheck(int256 x, int256 y, int256 z)`: Triggers an interaction check for the element at (x,y,z) with its neighbors based on element type rules. Can modify element states or trigger events.
5.  `getElementState(int256 x, int256 y, int256 z)`: Returns the current state (`ElementState` struct) of the element at the given coordinates.
6.  `getElementNFTId(int256 x, int256 y, int256 z)`: Returns the Element NFT token ID for the element at the given coordinates.
7.  `getCoordinatesByTokenId(uint256 tokenId)`: Returns the 3D coordinates for a given Element NFT token ID.
8.  `getElementOwner(int256 x, int256 y, int256 z)`: Returns the owner address of the element at the given coordinates. Helper function.
9.  `decayElement(int256 x, int256 y, int256 z)`: Calculates and applies energy decay to an element based on time elapsed since last update/placement. Can be called by anyone (incentivized cleanup). Triggers `removeElement` if energy drops to zero.
10. `removeElement(int256 x, int256 y, int256 z)`: Internal function to remove an element, burning its NFT and clearing its state from storage.
11. `cleanupDecayedElements(int256[] calldata xCoords, int256[] calldata yCoords, int256[] calldata zCoords)`: Allows anyone to trigger decay checks for a list of coordinates. Useful for batch processing decayed elements.
12. `burnElement(uint256 tokenId)`: Allows the owner of an Element NFT to explicitly burn it, removing the element from the canvas.
13. `getElementEnergy(int256 x, int256 y, int256 z)`: Returns the current energy level of an element, accounting for decay.
14. `getTimeSincePlacement(int256 x, int256 y, int256 z)`: Returns the time elapsed in seconds since an element was placed or last reinforced/decayed.
15. `getDecayStatus(int256 x, int256 y, int256 z)`: Calculates and returns the *potential* energy after accounting for decay since the last update, *without* modifying the state.
16. `isOccupied(int256 x, int256 y, int256 z)`: Checks if the given coordinates are occupied by an element.
17. `getNeighbors(int256 x, int256 y, int256 z)`: Returns a list of coordinates of existing neighboring elements (26 potential neighbors in 3D, plus the center if querying from outside).
18. `isCoordValid(int256 x, int256 y, int256 z)`: Checks if coordinates are within the defined canvas bounds.
19. `addElementType(string memory name, uint256 placementCost, uint256 initialEnergy, uint256 decayRatePerSec, uint256 reinforceCost)`: Owner function to define a new type of element with its properties.
20. `updateElementTypeParams(uint256 elementTypeIndex, uint256 placementCost, uint256 initialEnergy, uint256 decayRatePerSec, uint256 reinforceCost)`: Owner function to modify parameters of an existing element type.
21. `getElementTypeDetails(uint256 elementTypeIndex)`: Returns the configuration details for a specific element type.
22. `getElementTypeCount()`: Returns the total number of defined element types.
23. `getCanvasConfig()`: Returns the global canvas configuration struct.
24. `setCanvasBounds(int256 minX, int256 minY, int256 minZ, int256 maxX, int256 maxY, int256 maxZ)`: Owner function to set the spatial limits of the canvas.
25. `getCanvasBounds()`: Returns the current spatial bounds of the canvas.
26. `setCanvasPlacementCostMultiplier(uint256 multiplier)`: Owner function to set a global multiplier for placement costs.
27. `setCanvasReinforceCostMultiplier(uint256 multiplier)`: Owner function to set a global multiplier for reinforcement costs.
28. `createSceneSnapshot(string memory description)`: Creates a snapshot NFT representing the state of the canvas at the time of minting. The tokenURI for this NFT would point to metadata describing the snapshot.
29. `getSceneDetails(uint256 sceneTokenId)`: Returns the details for a specific Scene NFT.
30. `getTotalScenes()`: Returns the total number of Scene NFTs minted.
31. `tokenURI(uint256 tokenId)`: Standard ERC721 function, overridden to provide metadata URI for both Element NFTs and Scene NFTs based on their type and state/details.
32. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function, overridden to indicate support for ERC721 and ERC165 interfaces.
33. `withdrawFunds()`: Owner function to withdraw accumulated Ether from the contract.
34. `setPaused(bool _paused)`: Owner function to pause/unpause core canvas interactions.
35. `getTotalElements()`: Returns the total number of Element NFTs ever minted (including burned ones, if counter isn't decreased, or could modify to track active count). Let's keep it simple and track total minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title DimensionalCanvas
/// @dev A generative, interactive 3D canvas where users place dynamic element NFTs.
/// Elements decay over time and can interact with neighbors. Specific states can be captured as Scene NFTs.

contract DimensionalCanvas is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // --- Errors ---
    error ElementAlreadyExists(int256 x, int256 y, int256 z);
    error ElementDoesNotExist(int256 x, int256 y, int256 z);
    error CoordOutOfBounds(int256 x, int256 y, int256 z);
    error InvalidElementType();
    error NotElementOwner();
    error InsufficientEnergy();
    error CannotReinforceFullyCharged();
    error NotSceneNFT();
    error IsSceneNFT(); // Used when attempting element operations on a scene NFT ID
    error CanvasIsPaused();


    // --- Structs ---

    /// @dev Represents a 3D coordinate.
    struct Coord {
        int256 x;
        int256 y;
        int256 z;
    }

    /// @dev Represents the state of an element at a specific coordinate.
    struct ElementState {
        address owner;
        uint256 elementTypeIndex;
        string color; // e.g., "#RRGGBB"
        uint256 placementTime; // block.timestamp when placed or last reinforced/decayed
        uint256 energy; // Current energy level, decays over time
    }

    /// @dev Configuration for different types of elements.
    struct ElementTypeConfig {
        string name;
        uint256 placementCost; // Base cost in wei
        uint256 initialEnergy;
        uint256 decayRatePerSec; // Energy lost per second
        uint256 reinforceCost; // Base cost to reinforce
    }

    /// @dev Global configuration for the canvas.
    struct CanvasConfig {
        int256 minX;
        int256 minY;
        int256 minZ;
        int256 maxX;
        int256 maxY;
        int256 maxZ;
        uint256 placementCostMultiplier; // Multiplier for placement costs (1000 = 1x)
        uint256 reinforceCostMultiplier; // Multiplier for reinforce costs (1000 = 1x)
        bool isPaused; // If true, placement/reinforcement is paused
    }

    /// @dev Details for a captured scene snapshot NFT.
    struct SceneDetails {
        address creator;
        uint256 timestamp;
        uint256 blockNumber;
        string description;
    }


    // --- State Variables ---

    /// @dev Stores the state of elements in the 3D space.
    mapping(int256 => mapping(int256 => mapping(int256 => ElementState))) private space;

    /// @dev Maps coordinates to the Element NFT token ID.
    mapping(int256 => mapping(int256 => mapping(int256 => uint256))) private elementTokenIdMap;

    /// @dev Maps Element NFT token ID to coordinates.
    mapping(uint256 => Coord) private elementCoordMap;

    /// @dev Counter for Element NFT token IDs. Token IDs start from 1.
    Counters.Counter private elementNFTCounter;

    /// @dev Maps token ID to true if it's a Scene NFT, false otherwise (or non-existent).
    mapping(uint256 => bool) private isSceneNFT;

    /// @dev Counter for Scene NFT token IDs. Using a large offset to avoid collision with element IDs.
    uint256 private constant SCENE_ID_OFFSET = 1_000_000_000;
    Counters.Counter private sceneNFTCounter;

    /// @dev Stores details for Scene NFTs.
    mapping(uint256 => SceneDetails) private sceneNFTDetails;

    /// @dev Stores configurations for different element types.
    mapping(uint256 => ElementTypeConfig) private elementTypes;

    /// @dev Counter for element types. Index starts from 0.
    uint256 private elementTypeCount;

    /// @dev Global canvas configuration.
    CanvasConfig public canvasConfig;


    // --- Events ---

    event ElementPlaced(uint256 indexed tokenId, address indexed owner, int256 x, int256 y, int256 z, uint256 elementTypeIndex, string color);
    event ElementReinforced(uint256 indexed tokenId, address indexed owner, int256 x, int256 y, int256 z, uint256 newEnergy);
    event ElementDecayed(uint256 indexed tokenId, int256 x, int256 y, int256 z, uint256 energyLost, uint256 newEnergy, bool removed);
    event ElementRemoved(uint256 indexed tokenId, address indexed owner, int256 x, int256 y, int256 z, string reason);
    event InteractionTriggered(int256 x, int256 y, int256 z, string interactionType, bytes32 interactionOutcomeHash); // Hash outcome as outcome can be complex
    event SceneSnapshotCreated(uint256 indexed tokenId, address indexed creator, string description);
    event ElementTypeAdded(uint256 indexed index, string name, uint256 placementCost, uint256 initialEnergy, uint256 decayRatePerSec, uint256 reinforceCost);
    event CanvasConfigUpdated(CanvasConfig newConfig);
    event Paused(address account);
    event Unpaused(address account);


    // --- Constructor ---

    constructor() ERC721("DimensionalCanvasElement", "DCE") Ownable(msg.sender) {
        // Set initial canvas bounds
        canvasConfig.minX = -50;
        canvasConfig.minY = -50;
        canvasConfig.minZ = -50;
        canvasConfig.maxX = 50;
        canvasConfig.maxY = 50;
        canvasConfig.maxZ = 50;

        // Set initial cost multipliers
        canvasConfig.placementCostMultiplier = 1000; // 1000 = 1x
        canvasConfig.reinforceCostMultiplier = 1000; // 1000 = 1x
        canvasConfig.isPaused = false;

        // Add some default element types (index 0, 1, ...)
        _addElementType("Basic Cube", 0.01 ether, 1000, 1, 0.005 ether); // low cost, decays
        _addElementType("Solid Wall", 0.1 ether, 5000, 0, 0);         // higher cost, no decay
        _addElementType("Spark Node", 0.05 ether, 500, 5, 0.02 ether); // interacts heavily, fast decay
    }


    // --- Modifiers ---

    modifier onlyExistingElement(int256 x, int256 y, int256 z) {
        if (!isOccupied(x, y, z)) {
            revert ElementDoesNotExist(x, y, z);
        }
        _;
    }

    modifier onlyElementOwner(int256 x, int256 y, int256 z) {
        onlyExistingElement(x, y, z);
        if (space[x][y][z].owner != msg.sender) {
            revert NotElementOwner();
        }
        _;
    }

    modifier whenNotPaused() {
        if (canvasConfig.isPaused) {
            revert CanvasIsPaused();
        }
        _;
    }


    // --- Core Canvas Interaction Functions ---

    /// @dev Allows a user to place a new element at specific coordinates.
    /// Mints an Element NFT and updates the canvas state.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    /// @param elementTypeIndex The index of the element type to place.
    /// @param color A string representing the element's color (e.g., hex code).
    function placeElement(
        int256 x,
        int256 y,
        int256 z,
        uint256 elementTypeIndex,
        string memory color
    ) external payable nonReentrant whenNotPaused {
        if (isOccupied(x, y, z)) {
            revert ElementAlreadyExists(x, y, z);
        }
        if (!isCoordValid(x, y, z)) {
            revert CoordOutOfBounds(x, y, z);
        }
        if (elementTypeIndex >= elementTypeCount) {
            revert InvalidElementType();
        }

        ElementTypeConfig storage elementType = elementTypes[elementTypeIndex];
        uint256 placementCost = (elementType.placementCost * canvasConfig.placementCostMultiplier) / 1000;
        if (msg.value < placementCost) {
            // Refund excess ether if sent more than required (optional but good practice)
             if (msg.value > 0) payable(msg.sender).transfer(msg.value); // Revert all if not enough
             revert ERC721InsufficientApproval(address(this), type(uint256).max); // Standard insufficient funds error
        }

        elementNFTCounter.increment();
        uint256 newTokenId = elementNFTCounter.current();

        // Set initial state
        ElementState memory newState = ElementState({
            owner: msg.sender,
            elementTypeIndex: elementTypeIndex,
            color: color,
            placementTime: block.timestamp,
            energy: elementType.initialEnergy
        });

        space[x][y][z] = newState;
        elementTokenIdMap[x][y][z] = newTokenId;
        elementCoordMap[newTokenId] = Coord({x: x, y: y, z: z});
        isSceneNFT[newTokenId] = false; // Explicitly mark as not a scene NFT

        _safeMint(msg.sender, newTokenId);

        // Refund excess ether if any
        if (msg.value > placementCost) {
            payable(msg.sender).transfer(msg.value - placementCost);
        }

        emit ElementPlaced(newTokenId, msg.sender, x, y, z, elementTypeIndex, color);
    }

    /// @dev Allows the owner of an element to reinforce it, increasing its energy.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    function reinforceElement(
        int256 x,
        int256 y,
        int256 z
    ) external payable onlyElementOwner(x, y, z) nonReentrant whenNotPaused {
        ElementState storage element = space[x][y][z];
        ElementTypeConfig storage elementType = elementTypes[element.elementTypeIndex];

        // First, apply decay to get current energy
        uint256 currentEnergy = getElementEnergy(x, y, z);
        element.energy = currentEnergy; // Update state based on decay calculation
        element.placementTime = block.timestamp; // Update timestamp *before* adding new energy

        if (element.energy >= elementType.initialEnergy) {
             // If already at full energy (or somehow more), just reset timestamp and return excess
            if (msg.value > 0) payable(msg.sender).transfer(msg.value);
            revert CannotReinforceFullyCharged();
        }

        uint256 reinforceCost = (elementType.reinforceCost * canvasConfig.reinforceCostMultiplier) / 1000;
        if (msg.value < reinforceCost) {
             if (msg.value > 0) payable(msg.sender).transfer(msg.value);
             revert ERC721InsufficientApproval(address(this), type(uint256).max); // Standard insufficient funds error
        }

        // Add energy up to the initial amount (max capacity)
        element.energy = element.energy + elementType.initialEnergy; // Add full initial energy, cap later
        if (element.energy > elementType.initialEnergy) {
            element.energy = elementType.initialEnergy; // Cap at initial energy
        }

        // Refund excess ether if any
        if (msg.value > reinforceCost) {
            payable(msg.sender).transfer(msg.value - reinforceCost);
        }

        emit ElementReinforced(elementTokenIdMap[x][y][z], msg.sender, x, y, z, element.energy);
    }

    /// @dev Triggers an interaction check for the element at (x,y,z) with its neighbors.
    /// This function would contain the core game/art logic for how different elements interact.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    function triggerInteractionCheck(
        int256 x,
        int256 y,
        int256 z
    ) external nonReentrant onlyExistingElement(x, y, z) {
        // This is a placeholder for complex interaction logic.
        // In a real contract, this would read the state of neighbors
        // and the element at (x,y,z) and potentially modify states,
        // emit specific events, or even trigger internal element placement/removal.

        // Example: Get element types of neighbors
        Coord[] memory neighborsCoords = getNeighbors(x, y, z);
        uint256[] memory neighborElementTypes = new uint256[](neighborsCoords.length);

        for(uint256 i = 0; i < neighborsCoords.length; i++) {
            if(isOccupied(neighborsCoords[i].x, neighborsCoords[i].y, neighborsCoords[i].z)) {
                 neighborElementTypes[i] = space[neighborsCoords[i].x][neighborsCoords[i].y][neighborsCoords[i].z].elementTypeIndex;
            } else {
                 // Use a marker value for empty space, or skip
                 neighborElementTypes[i] = type(uint256).max; // Marker for empty
            }
        }

        ElementState storage centralElement = space[x][y][z];
        uint256 centralElementType = centralElement.elementTypeIndex;

        // --- Interaction Logic Placeholder ---
        // Based on centralElementType and neighborElementTypes, define rules.
        // E.g., if central is type 'Spark' and neighbor is type 'Fuel', maybe:
        // 1. Reduce energy of both.
        // 2. Change color of central to 'Fire'.
        // 3. Emit a special 'Combustion' event.
        // 4. If energy drops to 0, call removeElement internally.

        bytes32 interactionOutcomeHash = keccak256(abi.encode(centralElementType, neighborElementTypes)); // Placeholder hash

        // Example simple logic: 'Spark' (type 2) next to 'Basic Cube' (type 0) reduces Spark energy
        if (centralElementType == 2) { // Assuming Spark is type 2
            for(uint256 i = 0; i < neighborElementTypes.length; i++) {
                if (neighborElementTypes[i] == 0) { // Assuming Basic Cube is type 0
                    // Apply decay/energy loss specific to this interaction
                    // This could be more complex than regular decay
                    centralElement.energy = centralElement.energy > 10 ? centralElement.energy - 10 : 0;
                    break; // Interact with one neighbor of this type
                }
            }
             // If energy hits zero after interaction, remove
            if (centralElement.energy == 0) {
                 removeElement(x, y, z);
            } else {
                 // Update timestamp after interaction modifies state
                 centralElement.placementTime = block.timestamp;
            }
        }
        // --- End Interaction Logic Placeholder ---


        emit InteractionTriggered(x, y, z, "Generic Interaction", interactionOutcomeHash);
    }


    // --- Element State & NFT Functions ---

    /// @dev Gets the current state of an element at the given coordinates.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    /// @return The ElementState struct.
    function getElementState(
        int256 x,
        int256 y,
        int256 z
    ) public view onlyExistingElement(x, y, z) returns (ElementState memory) {
        ElementState storage element = space[x][y][z];
        // Return state with energy accounting for decay
        uint256 currentEnergy = getDecayStatus(x, y, z);
        ElementState memory currentState = element;
        currentState.energy = currentEnergy;
        return currentState;
    }

    /// @dev Gets the Element NFT token ID for the element at the given coordinates.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    /// @return The Element NFT token ID.
    function getElementNFTId(
        int255 x,
        int255 y,
        int255 z
    ) public view onlyExistingElement(x, y, z) returns (uint256) {
        return elementTokenIdMap[x][y][z];
    }

     /// @dev Gets the 3D coordinates for a given Element NFT token ID.
     /// @param tokenId The Element NFT token ID.
     /// @return The Coord struct (x, y, z).
     function getCoordinatesByTokenId(uint256 tokenId) public view returns (Coord memory) {
         if (isSceneNFT[tokenId]) revert IsSceneNFT();
         Coord memory coord = elementCoordMap[tokenId];
         if (!isOccupied(coord.x, coord.y, coord.z) || elementTokenIdMap[coord.x][coord.y][coord.z] != tokenId) {
             // This should not happen if mappings are consistent, but good check
             revert ElementDoesNotExist(coord.x, coord.y, coord.z); // Indicate issue if mapping is stale/wrong
         }
         return coord;
     }

     /// @dev Gets the owner of the element at the given coordinates.
     /// @param x The X coordinate.
     /// @param y The Y coordinate.
     /// @param z The Z coordinate.
     /// @return The owner address.
     function getElementOwner(int255 x, int255 y, int255 z) public view onlyExistingElement(x, y, z) returns (address) {
        return space[x][y][z].owner;
     }


    /// @dev Calculates and applies energy decay to an element.
    /// Can be called by anyone. Incentivizes users/bots to clean up decayed elements.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    function decayElement(
        int256 x,
        int256 y,
        int256 z
    ) public nonReentrant onlyExistingElement(x, y, z) {
        ElementState storage element = space[x][y][z];
        ElementTypeConfig storage elementType = elementTypes[element.elementTypeIndex];

        if (elementType.decayRatePerSec == 0) {
            // No decay for this element type
            return;
        }

        uint256 timeElapsed = block.timestamp - element.placementTime;
        uint256 energyLost = timeElapsed * elementType.decayRatePerSec;

        uint256 initialEnergy = element.energy; // Store initial energy before decay calculation
        uint256 newEnergy = element.energy > energyLost ? element.energy - energyLost : 0;

        element.energy = newEnergy;
        element.placementTime = block.timestamp; // Update timestamp even if not removed

        bool removed = false;
        if (newEnergy == 0) {
            removeElement(x, y, z);
            removed = true;
        }

        emit ElementDecayed(elementTokenIdMap[x][y][z], x, y, z, energyLost, newEnergy, removed);
    }

    /// @dev Internal function to remove an element and burn its NFT.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    function removeElement(
        int256 x,
        int256 y,
        int256 z
    ) internal onlyExistingElement(x, y, z) {
        uint256 tokenId = elementTokenIdMap[x][y][z];
        address owner = space[x][y][z].owner;

        // Clear state from mappings
        delete space[x][y][z];
        delete elementTokenIdMap[x][y][z];
        delete elementCoordMap[tokenId];

        // Burn the NFT
        _burn(owner, tokenId); // Use _burn directly as owner is known and checks are done

        emit ElementRemoved(tokenId, owner, x, y, z, "Decayed to zero energy");
    }

    /// @dev Allows triggering decay checks for a batch of coordinates.
    /// Useful for external services to maintain the canvas state efficiently.
    /// @param xCoords Array of X coordinates.
    /// @param yCoords Array of Y coordinates. Must match xCoords and zCoords length.
    /// @param zCoords Array of Z coordinates. Must match xCoords and yCoords length.
    function cleanupDecayedElements(
        int256[] calldata xCoords,
        int256[] calldata yCoords,
        int256[] calldata zCoords
    ) external nonReentrant {
        require(xCoords.length == yCoords.length && xCoords.length == zCoords.length, "Coordinate arrays must have same length");

        for (uint256 i = 0; i < xCoords.length; i++) {
             int256 x = xCoords[i];
             int256 y = yCoords[i];
             int256 z = zCoords[i];
            // Check if element still exists before attempting decay
            if (isOccupied(x, y, z)) {
                // This calls the public decayElement function, which handles checks internally
                decayElement(x, y, z);
            }
        }
    }

    /// @dev Allows the owner of an Element NFT to burn it, removing the element.
    /// @param tokenId The Element NFT token ID.
    function burnElement(uint256 tokenId) external nonReentrant {
        if (isSceneNFT[tokenId]) revert IsSceneNFT();
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

        Coord memory coord = elementCoordMap[tokenId];
        if (!isOccupied(coord.x, coord.y, coord.z) || elementTokenIdMap[coord.x][coord.y][coord.z] != tokenId) {
             revert ElementDoesNotExist(coord.x, coord.y, coord.z);
        }

        // Removal logic is in the internal removeElement function
        removeElement(coord.x, coord.y, coord.z);

        emit ElementRemoved(tokenId, msg.sender, coord.x, coord.y, coord.z, "Burned by owner");
    }


     /// @dev Gets the current energy level of an element, accounting for decay since last update.
     /// Does NOT modify the state.
     /// @param x The X coordinate.
     /// @param y The Y coordinate.
     /// @param z The Z coordinate.
     /// @return The calculated current energy level.
     function getElementEnergy(int256 x, int256 y, int256 z) public view onlyExistingElement(x, y, z) returns (uint256) {
        return getDecayStatus(x, y, z);
     }

     /// @dev Calculates the time elapsed in seconds since an element was placed or last state update.
     /// @param x The X coordinate.
     /// @param y The Y coordinate.
     /// @param z The Z coordinate.
     /// @return Time elapsed in seconds.
     function getTimeSincePlacement(int222 x, int222 y, int222 z) public view onlyExistingElement(x, y, z) returns (uint256) {
        return block.timestamp - space[x][y][z].placementTime;
     }

     /// @dev Calculates the energy level of an element after accounting for decay since its last state update.
     /// This is a pure calculation and does not modify the element's state in storage.
     /// @param x The X coordinate.
     /// @param y The Y coordinate.
     /// @param z The Z coordinate.
     /// @return The calculated energy level after decay.
     function getDecayStatus(int256 x, int256 y, int256 z) public view onlyExistingElement(x, y, z) returns (uint256) {
        ElementState storage element = space[x][y][z];
        ElementTypeConfig storage elementType = elementTypes[element.elementTypeIndex];

        if (elementType.decayRatePerSec == 0) {
            return element.energy; // No decay
        }

        uint256 timeElapsed = block.timestamp - element.placementTime;
        uint256 energyLost = timeElapsed * elementType.decayRatePerSec;

        if (element.energy > energyLost) {
            return element.energy - energyLost;
        } else {
            return 0;
        }
     }


    // --- Spatial Query Functions ---

    /// @dev Checks if the given coordinates are occupied by an element.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    /// @return True if occupied, false otherwise.
    function isOccupied(
        int256 x,
        int256 y,
        int256 z
    ) public view returns (bool) {
        // An element exists at the coordinate if the owner address is not zero
        return space[x][y][z].owner != address(0);
    }

    /// @dev Gets the coordinates of existing neighboring elements.
    /// Considers all 26 adjacent positions in a 3D grid (including diagonals).
    /// @param x The X coordinate of the center element.
    /// @param y The Y coordinate of the center element.
    /// @param z The Z coordinate of the center element.
    /// @return An array of Coord structs for existing neighbors.
    function getNeighbors(
        int256 x,
        int256 y,
        int256 z
    ) public view returns (Coord[] memory) {
        Coord[] memory neighbors = new Coord[](26); // Max 26 neighbors
        uint256 count = 0;

        for (int256 dx = -1; dx <= 1; dx++) {
            for (int256 dy = -1; dy <= 1; dy++) {
                for (int256 dz = -1; dz <= 1; dz++) {
                    // Skip the center coordinate itself
                    if (dx == 0 && dy == 0 && dz == 0) {
                        continue;
                    }

                    int256 nx = x + dx;
                    int256 ny = y + dy;
                    int256 nz = z + dz;

                    // Optional: Check bounds if neighbors must be within bounds
                    // if (!isCoordValid(nx, ny, nz)) {
                    //     continue;
                    // }

                    if (isOccupied(nx, ny, nz)) {
                        neighbors[count] = Coord({x: nx, y: ny, z: nz});
                        count++;
                    }
                }
            }
        }

        // Resize the array to the actual number of neighbors found
        Coord[] memory result = new Coord[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = neighbors[i];
        }
        return result;
    }

    /// @dev Checks if coordinates are within the defined canvas bounds.
    /// @param x The X coordinate.
    /// @param y The Y coordinate.
    /// @param z The Z coordinate.
    /// @return True if within bounds, false otherwise.
    function isCoordValid(
        int256 x,
        int256 y,
        int256 z
    ) public view returns (bool) {
        return (x >= canvasConfig.minX && x <= canvasConfig.maxX &&
                y >= canvasConfig.minY && y <= canvasConfig.maxY &&
                z >= canvasConfig.minZ && z <= canvasConfig.maxZ);
    }


    // --- Element Type Management Functions ---

    /// @dev Adds a new element type definition. Only callable by the owner.
    /// @param name The name of the element type.
    /// @param placementCost Base cost in wei to place this type.
    /// @param initialEnergy Initial energy level when placed.
    /// @param decayRatePerSec Energy loss per second for this type.
    /// @param reinforceCost Base cost in wei to reinforce this type.
    function addElementType(
        string memory name,
        uint256 placementCost,
        uint256 initialEnergy,
        uint256 decayRatePerSec,
        uint256 reinforceCost
    ) public onlyOwner {
        elementTypes[elementTypeCount] = ElementTypeConfig({
            name: name,
            placementCost: placementCost,
            initialEnergy: initialEnergy,
            decayRatePerSec: decayRatePerSec,
            reinforceCost: reinforceCost
        });
        elementTypeCount++;
        emit ElementTypeAdded(elementTypeCount - 1, name, placementCost, initialEnergy, decayRatePerSec, reinforceCost);
    }

    /// @dev Updates parameters for an existing element type. Only callable by the owner.
    /// @param elementTypeIndex The index of the element type to update.
    /// @param placementCost New base placement cost.
    /// @param initialEnergy New initial energy.
    /// @param decayRatePerSec New decay rate.
    /// @param reinforceCost New reinforce cost.
    function updateElementTypeParams(
        uint256 elementTypeIndex,
        uint256 placementCost,
        uint256 initialEnergy,
        uint256 decayRatePerSec,
        uint256 reinforceCost
    ) public onlyOwner {
        if (elementTypeIndex >= elementTypeCount) {
            revert InvalidElementType();
        }
        ElementTypeConfig storage elementType = elementTypes[elementTypeIndex];
        elementType.placementCost = placementCost;
        elementType.initialEnergy = initialEnergy;
        elementType.decayRatePerSec = decayRatePerSec;
        elementType.reinforceCost = reinforceCost;

        // Re-emit event with updated details
        emit ElementTypeAdded(elementTypeIndex, elementType.name, placementCost, initialEnergy, decayRatePerSec, reinforceCost);
    }

    /// @dev Gets the configuration details for a specific element type.
    /// @param elementTypeIndex The index of the element type.
    /// @return The ElementTypeConfig struct.
    function getElementTypeDetails(uint256 elementTypeIndex) public view returns (ElementTypeConfig memory) {
         if (elementTypeIndex >= elementTypeCount) {
            revert InvalidElementType();
        }
        return elementTypes[elementTypeIndex];
    }

    /// @dev Gets the total number of defined element types.
    /// @return The count of element types.
    function getElementTypeCount() public view returns (uint256) {
        return elementTypeCount;
    }


    // --- Canvas Configuration Functions ---

    /// @dev Gets the global canvas configuration.
    /// @return The CanvasConfig struct.
    function getCanvasConfig() public view returns (CanvasConfig memory) {
        return canvasConfig;
    }

    /// @dev Sets the spatial limits of the canvas. Only callable by the owner.
    /// @param minX Minimum X coordinate.
    /// @param minY Minimum Y coordinate.
    /// @param minZ Minimum Z coordinate.
    /// @param maxX Maximum X coordinate.
    /// @param maxY Maximum Y coordinate.
    /// @param maxZ Maximum Z coordinate.
    function setCanvasBounds(
        int256 minX,
        int256 minY,
        int256 minZ,
        int256 maxX,
        int256 maxY,
        int256 maxZ
    ) public onlyOwner {
         // Basic validation
         require(minX <= maxX && minY <= maxY && minZ <= maxZ, "Invalid bounds");
         canvasConfig.minX = minX;
         canvasConfig.minY = minY;
         canvasConfig.minZ = minZ;
         canvasConfig.maxX = maxX;
         canvasConfig.maxY = maxY;
         canvasConfig.maxZ = maxZ;
         emit CanvasConfigUpdated(canvasConfig);
    }

    /// @dev Gets the current spatial bounds of the canvas.
    /// @return minX, minY, minZ, maxX, maxY, maxZ.
    function getCanvasBounds() public view returns (int256, int256, int256, int256, int256, int256) {
        return (
            canvasConfig.minX,
            canvasConfig.minY,
            canvasConfig.minZ,
            canvasConfig.maxX,
            canvasConfig.maxY,
            canvasConfig.maxZ
        );
    }

    /// @dev Sets the global multiplier for element placement costs.
    /// @param multiplier The new multiplier (e.g., 1000 for 1x, 500 for 0.5x, 2000 for 2x).
    function setCanvasPlacementCostMultiplier(uint256 multiplier) public onlyOwner {
        canvasConfig.placementCostMultiplier = multiplier;
        emit CanvasConfigUpdated(canvasConfig);
    }

     /// @dev Sets the global multiplier for element reinforcement costs.
     /// @param multiplier The new multiplier.
    function setCanvasReinforceCostMultiplier(uint256 multiplier) public onlyOwner {
        canvasConfig.reinforceCostMultiplier = multiplier;
        emit CanvasConfigUpdated(canvasConfig);
    }


    // --- Scene Snapshot Functions ---

    /// @dev Creates a snapshot NFT representing the state of the canvas at this moment.
    /// The actual state data isn't stored on-chain due to gas costs; the NFT
    /// points to metadata describing the snapshot time and allowing off-chain rendering.
    /// @param description A brief description of the snapshot.
    /// @return The token ID of the newly minted Scene NFT.
    function createSceneSnapshot(string memory description) external nonReentrant whenNotPaused returns (uint256) {
        sceneNFTCounter.increment();
        uint256 newSceneTokenId = SCENE_ID_OFFSET + sceneNFTCounter.current(); // Use offset for scene IDs

        sceneNFTDetails[newSceneTokenId] = SceneDetails({
            creator: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            description: description
        });
        isSceneNFT[newSceneTokenId] = true; // Mark as a scene NFT

        _safeMint(msg.sender, newSceneTokenId);

        emit SceneSnapshotCreated(newSceneTokenId, msg.sender, description);
        return newSceneTokenId;
    }

    /// @dev Gets the details for a specific Scene NFT.
    /// @param sceneTokenId The Scene NFT token ID.
    /// @return The SceneDetails struct.
    function getSceneDetails(uint256 sceneTokenId) public view returns (SceneDetails memory) {
        if (!isSceneNFT[sceneTokenId]) {
             revert NotSceneNFT();
        }
        return sceneNFTDetails[sceneTokenId];
    }

    /// @dev Gets the total number of Scene NFTs minted.
    /// @return The count of Scene NFTs.
    function getTotalScenes() public view returns (uint256) {
        return sceneNFTCounter.current();
    }


    // --- ERC721 Standard Overrides & Helpers ---

    /// @dev See {ERC721-tokenURI}.
    /// Provides metadata URI for both Element and Scene NFTs.
    /// Assumes a metadata server/service will handle the actual JSON based on the URI returned.
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned

        if (isSceneNFT[tokenId]) {
            // Return URI for Scene NFT metadata
            // e.g., "https://metadata.canvas.xyz/scene/{tokenId}"
            return string(abi.encodePacked("https://metadata.canvas.xyz/scene/", tokenId.toString()));
        } else {
            // Return URI for Element NFT metadata
            // e.g., "https://metadata.canvas.xyz/element/{tokenId}"
             Coord memory coord = elementCoordMap[tokenId];
             // Check if the element still exists at the expected coordinate
             if (!isOccupied(coord.x, coord.y, coord.z) || elementTokenIdMap[coord.x][coord.y][coord.z] != tokenId) {
                // This case means the element was likely removed (decayed/burned) but the NFT might still exist (though _requireOwned checks ownership).
                // In a full implementation, _burn might clear isSceneNFT/elementCoordMap, or this URI should indicate the element is gone.
                // For this example, assume if _requireOwned passes, it exists, or the metadata server handles "burned" state.
             }
            return string(abi.encodePacked("https://metadata.canvas.xyz/element/", tokenId.toString()));
        }
    }

    /// @dev See {ERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) override public view returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Admin & Utility Functions ---

    /// @dev Allows the contract owner to withdraw accumulated Ether.
    function withdrawFunds() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    /// @dev Pauses or unpauses core canvas interactions (place, reinforce, snapshot).
    /// @param _paused True to pause, false to unpause.
    function setPaused(bool _paused) public onlyOwner {
        canvasConfig.isPaused = _paused;
        if (_paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
        emit CanvasConfigUpdated(canvasConfig);
    }

    /// @dev Gets the total number of Element NFTs ever minted.
    /// @return The total count of Element NFTs.
    function getTotalElements() public view returns (uint256) {
        return elementNFTCounter.current();
    }
}
```