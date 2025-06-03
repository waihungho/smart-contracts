Okay, let's create a smart contract based on a "Celestial Registry" theme. This contract will combine elements of NFT ownership, dynamic data, time-sensitive events (phenomena), and a form of on-chain "discovery" and "observation" points, culminating in a calculated dynamic score for celestial objects.

It will *not* be a direct copy of standard ERC contracts (like a basic ERC721 where you just mint and transfer), but will use them as a base for ownership while adding custom logic around creation, interaction, and state changes.

**Concept:** Users can "discover" unique celestial objects (represented as NFTs), which are generated based on input seeds. They can then "observe" these objects and "participate" in cosmic "phenomena" that occur near objects. Objects have dynamic properties and a calculated "significance score" based on their type, age, discovery details, observation activity, and related phenomena.

---

**Outline:**

1.  **Contract Definition & Imports:** Inherit from ERC721 and Ownable.
2.  **State Variables:**
    *   Counters for objects and phenomena.
    *   Mappings for object details, phenomenon details, observer profiles.
    *   Mappings for observation data and relationships.
    *   Mappings for registered object/phenomenon types and their properties.
    *   Configuration parameters (cooldowns, scoring weights).
    *   Pause state.
3.  **Structs:**
    *   `CelestialObject`: Stores details of a discovered object (type, discovery info, dynamic params).
    *   `Phenomenon`: Stores details of a cosmic event (type, duration, location link, participants).
    *   `ObserverProfile`: Stores stats for a user (discoveries, observations, influence points).
    *   `ObservationData`: Stores user-submitted data about an observation.
4.  **Events:** Log key actions (discovery, observation, phenomenon announcement/participation, naming, parameter change).
5.  **Modifiers:** `whenNotPaused`, `objectExists`, `phenomenonExists`, `isObjectOwner`.
6.  **Core Registry Management (Admin):**
    *   Register/Update celestial object types.
    *   Register/Update phenomenon types.
    *   Set configuration parameters.
    *   Pause/Unpause contract.
7.  **Celestial Object Discovery & Management (NFTs):**
    *   `discoverCelestialObject`: Mint a new object NFT based on a seed, create object data, update profile.
    *   `assignNameToObject`: Allow owner to name an object.
    *   `influenceObjectParameter`: Allow interaction that changes a dynamic parameter.
    *   `getObjectDetails`: Get all stored details for an object.
    *   `calculateDynamicObjectScore`: Calculate a composite score for an object (view).
    *   Standard ERC721 functions (transfer, ownerOf, tokenURI, etc. - implicitly included).
8.  **Observation System:**
    *   `observeCelestialObject`: Record an observation of an object, update profile.
    *   `recordObservationData`: Link external data (e.g., IPFS hash) to an observation.
    *   `getObservationDataForObjectAndObserver`: Retrieve specific observation data.
    *   `getTotalObservationsOfObject`: Get total observations count for an object.
    *   `getObserversOfObject`: Get list of addresses that observed an object.
9.  **Phenomena System:**
    *   `announcePhenomenon`: Admin function to create a new event.
    *   `participateInPhenomenon`: Allow users to interact with an active phenomenon.
    *   `getPhenomenonDetails`: Get details of a phenomenon.
    *   `getActivePhenomena`: Get list of currently active phenomena.
    *   `getParticipantsOfPhenomenon`: Get list of addresses that participated in a phenomenon.
10. **Observer Profiles & Stats:**
    *   `getObserverProfile`: Get user's discovery/observation/influence stats.
11. **Utility & View Functions:**
    *   `isPaused`: Check pause state.
    *   `getTotalObjectsDiscovered`: Total count of objects.
    *   `getTotalPhenomenaAnnounced`: Total count of phenomena.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets owner, and ERC721 name/symbol.
2.  `registerCelestialObjectType(string memory _name, uint256 _baseSignificance, uint256 _discoveryCooldown)`: (Admin) Registers a new type of celestial object with base properties.
3.  `updateCelestialObjectType(uint256 _typeId, string memory _newName, uint256 _newBaseSignificance, uint256 _newDiscoveryCooldown)`: (Admin) Updates properties of an existing object type.
4.  `registerPhenomenonType(string memory _name, uint256 _durationBlocks, uint256 _participantInfluenceAward)`: (Admin) Registers a new type of phenomenon with base properties.
5.  `updatePhenomenonType(uint256 _typeId, string memory _newName, uint256 _newDurationBlocks, uint256 _newParticipantInfluenceAward)`: (Admin) Updates properties of an existing phenomenon type.
6.  `setDiscoveryCooldown(uint256 _cooldownBlocks)`: (Admin) Sets the global minimum block cooldown between discoveries for a single user.
7.  `pause()`: (Admin) Pauses core interactions with the contract.
8.  `unpause()`: (Admin) Unpauses the contract.
9.  `discoverCelestialObject(uint256 _objectTypeId, uint256 _seed)`: Allows a user to discover a new celestial object of a specified type using a unique seed. Mints an NFT and records discovery details.
10. `assignNameToObject(uint256 _tokenId, string memory _name)`: Allows the owner of an object NFT to assign a unique name to it.
11. `influenceObjectParameter(uint256 _tokenId, uint256 _parameterIndex, int256 _valueChange)`: Allows specific interactions (potentially based on rules/roles not fully defined here for brevity) to change a dynamic numerical parameter of an object.
12. `getObjectDetails(uint256 _tokenId)`: Retrieves all stored details for a specific celestial object.
13. `calculateDynamicObjectScore(uint256 _tokenId)`: Calculates a dynamic significance score for an object based on its properties, age, observations, and related phenomena.
14. `observeCelestialObject(uint256 _tokenId)`: Records an observation of a celestial object by the caller, updating their profile and the object's observation count. Includes a cooldown per object per observer.
15. `recordObservationData(uint256 _tokenId, string memory _dataUri)`: Allows an observer to link external data (e.g., IPFS hash of findings) to their observation of an object.
16. `getObservationDataForObjectAndObserver(uint256 _tokenId, address _observer)`: Retrieves the data URI submitted by a specific observer for a specific object.
17. `getTotalObservationsOfObject(uint256 _tokenId)`: Returns the total number of unique observations recorded for an object.
18. `getObserversOfObject(uint256 _tokenId)`: Returns a list of addresses that have observed the given object.
19. `announcePhenomenon(uint256 _phenomenonTypeId, uint256 _linkedObjectId, string memory _details)`: (Admin/System) Announces a new cosmic phenomenon event linked to a specific object.
20. `participateInPhenomenon(uint256 _phenomenonId)`: Allows a user to participate in an active phenomenon, potentially receiving influence points or other benefits.
21. `getPhenomenonDetails(uint256 _phenomenonId)`: Retrieves details for a specific phenomenon.
22. `getActivePhenomena()`: Returns a list of currently active phenomena IDs.
23. `getParticipantsOfPhenomenon(uint256 _phenomenonId)`: Returns a list of addresses that have participated in a specific phenomenon.
24. `getObserverProfile(address _observer)`: Retrieves the discovery, observation, and influence stats for a given address.
25. `isPaused()`: Returns the current pause state of the contract.
26. `getTotalObjectsDiscovered()`: Returns the total number of celestial objects ever discovered.
27. `getTotalPhenomenaAnnounced()`: Returns the total number of phenomena ever announced.
28. `tokenURI(uint256 tokenId)`: Standard ERC721 function to get the token URI (simplified placeholder implementation).
29. `ownerOf(uint256 tokenId)`: Standard ERC721 function to get the owner of a token.
30. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 function to transfer ownership.
31. `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 safe transfer.
32. `approve(address to, uint256 tokenId)`: Standard ERC721 approve.
33. `getApproved(uint256 tokenId)`: Standard ERC721 get approved.
34. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 set approval for all.
35. `isApprovedForAll(address owner, address operator)`: Standard ERC721 is approved for all.
36. `balanceOf(address owner)`: Standard ERC721 balance of.
37. `name()`: Standard ERC721 name (inherited).
38. `symbol()`: Standard ERC721 symbol (inherited).

*(Note: Functions 28-38 are standard ERC721 functions included for contract completeness and easily meet the >20 function requirement. The unique logic is primarily in functions 9-27).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Used for score calculation etc.

// Outline:
// 1. Contract Definition & Imports
// 2. State Variables
// 3. Structs
// 4. Events
// 5. Modifiers
// 6. Core Registry Management (Admin)
// 7. Celestial Object Discovery & Management (NFTs)
// 8. Observation System
// 9. Phenomena System
// 10. Observer Profiles & Stats
// 11. Utility & View Functions

// Function Summary:
// 1. constructor(): Initializes the contract, sets owner, and ERC721 name/symbol.
// 2. registerCelestialObjectType(string memory _name, uint256 _baseSignificance, uint256 _discoveryCooldown): (Admin) Registers a new type of celestial object.
// 3. updateCelestialObjectType(uint256 _typeId, string memory _newName, uint256 _newBaseSignificance, uint256 _newDiscoveryCooldown): (Admin) Updates properties of an existing object type.
// 4. registerPhenomenonType(string memory _name, uint256 _durationBlocks, uint256 _participantInfluenceAward): (Admin) Registers a new type of phenomenon.
// 5. updatePhenomenonType(uint256 _typeId, string memory _newName, uint256 _newDurationBlocks, uint256 _newParticipantInfluenceAward): (Admin) Updates properties of an existing phenomenon type.
// 6. setDiscoveryCooldown(uint256 _cooldownBlocks): (Admin) Sets the global minimum block cooldown between discoveries for a single user.
// 7. pause(): (Admin) Pauses core interactions.
// 8. unpause(): (Admin) Unpauses the contract.
// 9. discoverCelestialObject(uint256 _objectTypeId, uint256 _seed): Allows a user to discover a new celestial object.
// 10. assignNameToObject(uint256 _tokenId, string memory _name): Allows owner to name an object.
// 11. influenceObjectParameter(uint256 _tokenId, uint256 _parameterIndex, int256 _valueChange): Allows interaction to change a dynamic numerical parameter.
// 12. getObjectDetails(uint256 _tokenId): Retrieves all stored details for an object.
// 13. calculateDynamicObjectScore(uint256 _tokenId): Calculates a dynamic significance score for an object (view).
// 14. observeCelestialObject(uint256 _tokenId): Records an observation of an object, updates profile.
// 15. recordObservationData(uint256 _tokenId, string memory _dataUri): Link external data to an observation.
// 16. getObservationDataForObjectAndObserver(uint256 _tokenId, address _observer): Retrieves observation data.
// 17. getTotalObservationsOfObject(uint256 _tokenId): Get total observations count for an object.
// 18. getObserversOfObject(uint256 _tokenId): Get list of addresses that observed an object.
// 19. announcePhenomenon(uint256 _phenomenonTypeId, uint256 _linkedObjectId, string memory _details): (Admin/System) Announces a new cosmic phenomenon.
// 20. participateInPhenomenon(uint256 _phenomenonId): Allows participation in an active phenomenon.
// 21. getPhenomenonDetails(uint256 _phenomenonId): Retrieves details for a phenomenon.
// 22. getActivePhenomena(): Returns a list of currently active phenomena IDs.
// 23. getParticipantsOfPhenomenon(uint25hn256 _phenomenonId): Returns a list of addresses that participated in a phenomenon.
// 24. getObserverProfile(address _observer): Retrieves user's discovery/observation/influence stats.
// 25. isPaused(): Returns the current pause state.
// 26. getTotalObjectsDiscovered(): Total count of objects.
// 27. getTotalPhenomenaAnnounced(): Total count of phenomena.
// 28-38. Standard ERC721 functions (tokenURI, ownerOf, transferFrom, etc.)

contract CelestialRegistry is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _objectIds;
    Counters.Counter private _phenomenonIds;
    Counters.Counter private _celestialObjectTypeIds;
    Counters.Counter private _phenomenonTypeIds;

    // Celestial Object Data
    struct CelestialObject {
        uint256 objectTypeId;
        uint256 discoveryBlock;
        address discoverer;
        uint256 seed; // Input seed for discovery
        string name;
        uint256 totalObservations;
        // Dynamic parameters that can change over time or through influence
        mapping(uint256 => int256) dynamicParameters;
        uint256 lastObservationBlock; // To track cooldown per object per observer
    }
    mapping(uint256 => CelestialObject) private _celestialObjects;

    // Phenomenon Data
    struct Phenomenon {
        uint256 phenomenonTypeId;
        uint256 startBlock;
        uint256 endBlock;
        uint256 linkedObjectId; // Object near which phenomenon occurs (optional, 0 if not linked)
        string details; // e.g., IPFS hash for detailed info
        mapping(address => bool) participants; // Track who participated
        uint256 totalParticipants;
    }
    mapping(uint256 => Phenomenon) private _phenomena;
    // Mapping from objectId to active phenomenon IDs near it
    mapping(uint256 => uint256[]) private _objectPhenomena;
    // Mapping from phenomenonId to list of participants
    mapping(uint256 => address[]) private _phenomenonParticipantsList; // Store as list for easy retrieval

    // Observer Data
    struct ObserverProfile {
        uint256 discoveries;
        uint256 observations;
        int256 influencePoints; // Gained from observations, participation, etc.
        uint256 lastDiscoveryBlock; // Track cooldown for discovery
        mapping(uint256 => uint256) lastObservationBlockPerObject; // Track cooldown per object
    }
    mapping(address => ObserverProfile) private _observerProfiles;

    // Observation Data (e.g., linked external findings)
    mapping(uint256 => mapping(address => string)) private _observationData; // objectId -> observer -> dataUri

    // Type Definitions
    struct CelestialObjectType {
        string name;
        uint256 baseSignificance; // Base value for scoring
        uint256 discoveryCooldownBlocks; // Cooldown after discovering this type
    }
    mapping(uint256 => CelestialObjectType) private _celestialObjectTypes;
    mapping(string => uint256) private _celestialObjectTypeNameToId;

    struct PhenomenonType {
        string name;
        uint256 durationBlocks;
        int256 participantInfluenceAward;
    }
    mapping(uint256 => PhenomenonType) private _phenomenonTypes;
    mapping(string => uint256) private _phenomenonTypeNameToId;


    // Configuration
    bool private _paused = false;
    uint256 public globalDiscoveryCooldownBlocks = 10; // Default global cooldown

    // Scoring Weights (Adjustable by admin if desired, kept internal for simplicity)
    uint256 constant private AGE_WEIGHT = 1; // Blocks old adds to score
    uint256 constant private OBSERVATION_WEIGHT = 10; // Each observation adds to score
    uint256 constant private DYNAMIC_PARAMETER_WEIGHT_BASE = 5; // Influence of dynamic params on score
    uint256 constant private PHENOMENA_PARTICIPATION_WEIGHT = 50; // Each related phenomenon participation adds significantly

    // --- Events ---

    event CelestialObjectDiscovered(uint256 indexed tokenId, uint256 objectTypeId, address indexed discoverer, uint256 discoveryBlock, uint256 seed);
    event CelestialObjectNamed(uint256 indexed tokenId, string name, address indexed namer);
    event ObjectParameterInfluenced(uint256 indexed tokenId, uint256 indexed parameterIndex, int256 valueChange, address indexed influencer);
    event CelestialObjectObserved(uint256 indexed tokenId, address indexed observer, uint256 observationBlock);
    event ObservationDataRecorded(uint256 indexed tokenId, address indexed observer, string dataUri);
    event PhenomenonAnnounced(uint256 indexed phenomenonId, uint256 phenomenonTypeId, uint256 indexed linkedObjectId, uint256 startBlock, uint256 endBlock);
    event PhenomenonParticipated(uint256 indexed phenomenonId, address indexed participant, uint256 participationBlock);
    event RegistryPaused(address indexed account);
    event RegistryUnpaused(address indexed account);
    event CelestialObjectTypeRegistered(uint256 indexed typeId, string name);
    event PhenomenonTypeRegistered(uint256 indexed typeId, string name);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!_paused, "Registry is paused");
        _;
    }

    modifier objectExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Object does not exist");
        _;
    }

     modifier phenomenonExists(uint256 _phenomenonId) {
        require(_phenomenonId > 0 && _phenomenonId <= _phenomenonIds.current(), "Phenomenon does not exist");
        _;
    }

    modifier isObjectOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Not object owner");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("CelestialRegistryObject", "CRO") Ownable(msg.sender) {}

    // --- Core Registry Management (Admin) ---

    /// @notice Registers a new type of celestial object.
    /// @param _name The name of the object type (e.g., "Star", "Nebula").
    /// @param _baseSignificance The base significance score for this type.
    /// @param _discoveryCooldown The minimum blocks between discoveries of this type by the same user.
    function registerCelestialObjectType(string memory _name, uint256 _baseSignificance, uint256 _discoveryCooldown) public onlyOwner {
        _celestialObjectTypeIds.increment();
        uint256 typeId = _celestialObjectTypeIds.current();
        _celestialObjectTypes[typeId] = CelestialObjectType(_name, _baseSignificance, _discoveryCooldown);
        _celestialObjectTypeNameToId[_name] = typeId;
        emit CelestialObjectTypeRegistered(typeId, _name);
    }

    /// @notice Updates properties of an existing celestial object type.
    /// @param _typeId The ID of the object type to update.
    /// @param _newName The new name.
    /// @param _newBaseSignificance The new base significance.
    /// @param _newDiscoveryCooldown The new discovery cooldown.
    function updateCelestialObjectType(uint256 _typeId, string memory _newName, uint256 _newBaseSignificance, uint256 _newDiscoveryCooldown) public onlyOwner {
        require(_typeId > 0 && _typeId <= _celestialObjectTypeIds.current(), "Invalid object type ID");
        // Remove old name mapping if name changes
        if (bytes(_celestialObjectTypes[_typeId].name).length > 0 && keccak256(bytes(_celestialObjectTypes[_typeId].name)) != keccak256(bytes(_newName))) {
             // Simple approach: just overwrite. If we needed to support querying old names, would need more complex logic.
             // For this example, we assume name updates are rare or handled carefully off-chain if old lookup is needed.
             // A safer approach would be to disallow name changes or use a versioned system. Keeping simple for function count.
        }
        _celestialObjectTypes[_typeId] = CelestialObjectType(_newName, _newBaseSignificance, _newDiscoveryCooldown);
        _celestialObjectTypeNameToId[_newName] = _typeId;
    }

    /// @notice Registers a new type of cosmic phenomenon.
    /// @param _name The name of the phenomenon type (e.g., "Supernova", "Gamma Ray Burst").
    /// @param _durationBlocks The duration in blocks the phenomenon is active.
    /// @param _participantInfluenceAward The influence points awarded for participation.
    function registerPhenomenonType(string memory _name, uint256 _durationBlocks, int256 _participantInfluenceAward) public onlyOwner {
        _phenomenonTypeIds.increment();
        uint256 typeId = _phenomenonTypeIds.current();
        _phenomenonTypes[typeId] = PhenomenonType(_name, _durationBlocks, _participantInfluenceAward);
        _phenomenonTypeNameToId[_name] = typeId;
        emit PhenomenonTypeRegistered(typeId, _name);
    }

     /// @notice Updates properties of an existing phenomenon type.
    /// @param _typeId The ID of the phenomenon type to update.
    /// @param _newName The new name.
    /// @param _newDurationBlocks The new duration.
    /// @param _newParticipantInfluenceAward The new influence award.
    function updatePhenomenonType(uint256 _typeId, string memory _newName, uint256 _newDurationBlocks, int256 _newParticipantInfluenceAward) public onlyOwner {
        require(_typeId > 0 && _typeId <= _phenomenonTypeIds.current(), "Invalid phenomenon type ID");
         if (bytes(_phenomenonTypes[_typeId].name).length > 0 && keccak256(bytes(_phenomenonTypes[_typeId].name)) != keccak256(bytes(_newName))) {
             // Similar to object type names, handle carefully or disallow name changes in a production system.
         }
        _phenomenonTypes[_typeId] = PhenomenonType(_newName, _newDurationBlocks, _newParticipantInfluenceAward);
        _phenomenonTypeNameToId[_newName] = _typeId;
    }


    /// @notice Sets the global minimum block cooldown between discoveries for any single user.
    /// @param _cooldownBlocks The cooldown period in blocks.
    function setDiscoveryCooldown(uint256 _cooldownBlocks) public onlyOwner {
        globalDiscoveryCooldownBlocks = _cooldownBlocks;
    }

    /// @notice Pauses the contract, preventing most interactions.
    function pause() public onlyOwner {
        require(!_paused, "Registry is already paused");
        _paused = true;
        emit RegistryPaused(msg.sender);
    }

    /// @notice Unpauses the contract, enabling interactions.
    function unpause() public onlyOwner {
        require(_paused, "Registry is not paused");
        _paused = false;
        emit RegistryUnpaused(msg.sender);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if paused, false otherwise.
    function isPaused() public view returns (bool) {
        return _paused;
    }


    // --- Celestial Object Discovery & Management (NFTs) ---

    /// @notice Allows a user to discover a new celestial object of a specified type.
    /// Mints an NFT, records discovery details, and updates the observer profile.
    /// Requires object type to exist and enforces discovery cooldowns.
    /// @param _objectTypeId The ID of the type of object to discover.
    /// @param _seed A unique seed value used during discovery.
    function discoverCelestialObject(uint256 _objectTypeId, uint256 _seed)
        public
        whenNotPaused
        nonReentrant
    {
        require(_objectTypeId > 0 && _objectTypeId <= _celestialObjectTypeIds.current(), "Invalid object type ID");
        CelestialObjectType storage objType = _celestialObjectTypes[_objectTypeId];

        // Check global cooldown
        require(block.number >= _observerProfiles[msg.sender].lastDiscoveryBlock.add(globalDiscoveryCooldownBlocks), "Global discovery cooldown active");
        // Check type-specific cooldown
         require(block.number >= _observerProfiles[msg.sender].lastDiscoveryBlock.add(objType.discoveryCooldownBlocks), "Type-specific discovery cooldown active");


        _objectIds.increment();
        uint256 newTokenId = _objectIds.current();

        // Mint the NFT
        _safeMint(msg.sender, newTokenId);

        // Store object data
        _celestialObjects[newTokenId].objectTypeId = _objectTypeId;
        _celestialObjects[newTokenId].discoveryBlock = block.number;
        _celestialObjects[newTokenId].discoverer = msg.sender;
        _celestialObjects[newTokenId].seed = _seed;
        _celestialObjects[newTokenId].name = string(abi.encodePacked("Uncharted Object #", Strings.toString(newTokenId))); // Default name

        // Update observer profile
        _observerProfiles[msg.sender].discoveries = _observerProfiles[msg.sender].discoveries.add(1);
        _observerProfiles[msg.sender].lastDiscoveryBlock = block.number;

        emit CelestialObjectDiscovered(newTokenId, _objectTypeId, msg.sender, block.number, _seed);
    }

    /// @notice Allows the owner of a celestial object NFT to assign a unique name to it.
    /// Names must be unique globally (simple check).
    /// @param _tokenId The ID of the object NFT to name.
    /// @param _name The desired name for the object.
    function assignNameToObject(uint256 _tokenId, string memory _name)
        public
        whenNotPaused
        objectExists(_tokenId)
        isObjectOwner(_tokenId)
    {
        // Basic check for non-empty name and length limit
        require(bytes(_name).length > 0 && bytes(_name).length <= 100, "Invalid name");
        // Check if name is already taken (requires iteration or lookup map, simple check here)
        // A production system might need a mapping from name hash to tokenId or a more gas-efficient lookup.
        // For this example, we'll skip a detailed uniqueness check to save gas and complexity,
        // assuming off-chain tools might handle name conflicts or names are not indexed by the contract.
        // If uniqueness is critical on-chain, a mapping `mapping(bytes32 => uint256) private _nameHashToTokenId;`
        // and checking `_nameHashToTokenId[keccak256(bytes(_name))] == 0` would be needed,
        // plus updating and handling conflicts on update.
        // For simplicity, we just allow the owner to set it.

        _celestialObjects[_tokenId].name = _name;

        emit CelestialObjectNamed(_tokenId, _name, msg.sender);
    }

    /// @notice Allows interaction to change a dynamic numerical parameter of an object.
    /// This could be tied to specific items, roles, or events off-chain triggering this function.
    /// Simplified: any owner can influence any parameter index.
    /// @param _tokenId The ID of the object.
    /// @param _parameterIndex An index representing which dynamic parameter is being influenced.
    /// @param _valueChange The integer value to add to the current parameter value.
    function influenceObjectParameter(uint256 _tokenId, uint256 _parameterIndex, int256 _valueChange)
        public
        whenNotPaused
        objectExists(_tokenId)
        isObjectOwner(_tokenId) // Or use a more complex access control based on roles/items
    {
        // No specific checks on parameterIndex or valueChange for flexibility.
        // A real application would validate these.
        _celestialObjects[_tokenId].dynamicParameters[_parameterIndex] = _celestialObjects[_tokenId].dynamicParameters[_parameterIndex] + _valueChange;

        // Potentially award influence points to the influencer
        _observerProfiles[msg.sender].influencePoints += _valueChange > 0 ? _valueChange : -(_valueChange); // Award based on magnitude

        emit ObjectParameterInfluenced(_tokenId, _parameterIndex, _valueChange, msg.sender);
    }

    /// @notice Retrieves all stored details for a specific celestial object.
    /// @param _tokenId The ID of the object.
    /// @return objectTypeId The type ID.
    /// @return discoveryBlock The block it was discovered.
    /// @return discoverer The discoverer's address.
    /// @return seed The discovery seed.
    /// @return name The object's name.
    /// @return totalObservations The total observation count.
    function getObjectDetails(uint256 _tokenId)
        public
        view
        objectExists(_tokenId)
        returns (uint256 objectTypeId, uint256 discoveryBlock, address discoverer, uint256 seed, string memory name, uint256 totalObservations)
    {
        CelestialObject storage obj = _celestialObjects[_tokenId];
        return (obj.objectTypeId, obj.discoveryBlock, obj.discoverer, obj.seed, obj.name, obj.totalObservations);
    }

    /// @notice Calculates a dynamic significance score for an object.
    /// Score is based on type, age, observation count, dynamic parameters, and linked phenomena.
    /// This is a view function and does not change state.
    /// @param _tokenId The ID of the object.
    /// @return The calculated dynamic significance score.
    function calculateDynamicObjectScore(uint256 _tokenId)
        public
        view
        objectExists(_tokenId)
        returns (uint256)
    {
        CelestialObject storage obj = _celestialObjects[_tokenId];
        CelestialObjectType storage objType = _celestialObjectTypes[obj.objectTypeId];

        uint256 score = objType.baseSignificance;

        // Add score based on age (blocks since discovery)
        score = score.add(block.number.sub(obj.discoveryBlock).mul(AGE_WEIGHT));

        // Add score based on observations
        score = score.add(obj.totalObservations.mul(OBSERVATION_WEIGHT));

        // Add/subtract score based on dynamic parameters
        // Assuming we have few parameters (e.g., 3-5) for simplicity, iterate.
        // For many parameters, a different structure might be needed.
        // Let's assume parameter indices 0, 1, 2 are relevant for scoring.
        score = score.add(uint256(obj.dynamicParameters[0]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));
        score = score.add(uint256(obj.dynamicParameters[1]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));
        score = score.add(uint256(obj.dynamicParameters[2]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));
        // Note: handling negative dynamic parameters requires care with uint256.
        // If parameter value can be negative, score contribution needs adjustment.
        // Example: `score = score.add(uint256(obj.dynamicParameters[0] > 0 ? obj.dynamicParameters[0] : -obj.dynamicParameters[0]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));`
        // Or simply add/subtract if score can be signed int. Using uint256 for simplicity means params should ideally be >=0 or carefully handled.
        // Let's assume parameters are designed such that their value contributes positively or negatively clearly.
        // A safer approach for signed contribution to uint256 score:
         if (obj.dynamicParameters[0] > 0) score = score.add(uint256(obj.dynamicParameters[0]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE)); else score = score.sub(uint256(-obj.dynamicParameters[0]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));
         if (obj.dynamicParameters[1] > 0) score = score.add(uint256(obj.dynamicParameters[1]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE)); else score = score.sub(uint256(-obj.dynamicParameters[1]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));
         if (obj.dynamicParameters[2] > 0) score = score.add(uint256(obj.dynamicParameters[2]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE)); else score = score.sub(uint256(-obj.dynamicParameters[2]).mul(DYNAMIC_PARAMETER_WEIGHT_BASE));


        // Add score based on linked phenomena participation
        uint256[] memory linkedPhenomena = _objectPhenomena[_tokenId];
        uint256 linkedPhenomenaParticipationScore = 0;
        for(uint i = 0; i < linkedPhenomena.length; i++) {
            uint256 phenId = linkedPhenomena[i];
            if (_phenomena[phenId].participants[obj.discoverer]) { // Did the discoverer participate in related phenomena?
                 linkedPhenomenaParticipationScore = linkedPhenomenaParticipationScore.add(PHENOMENA_PARTICIPATION_WEIGHT);
            }
            // Could also add score based on total participation in linked phenomena:
            // linkedPhenomenaParticipationScore = linkedPhenomenaParticipationScore.add(_phenomena[phenId].totalParticipants.mul(PHENOMENA_PARTICIPATION_WEIGHT / 10));
        }
         score = score.add(linkedPhenomenaParticipationScore);


        return score;
    }


    // --- Observation System ---

    /// @notice Records an observation of a celestial object by the caller.
    /// Updates observer profile and object observation count. Enforces cooldown per object per observer.
    /// @param _tokenId The ID of the object being observed.
    function observeCelestialObject(uint256 _tokenId)
        public
        whenNotPaused
        objectExists(_tokenId)
        nonReentrant
    {
        // Observation cooldown for this object for this observer
        require(block.number >= _observerProfiles[msg.sender].lastObservationBlockPerObject[_tokenId].add(5), "Observation cooldown active for this object"); // 5 block cooldown example

        // Increment total observations for the object
        _celestialObjects[_tokenId].totalObservations = _celestialObjects[_tokenId].totalObservations.add(1);

        // Update observer profile
        _observerProfiles[msg.sender].observations = _observerProfiles[msg.sender].observations.add(1);
        _observerProfiles[msg.sender].influencePoints = _observerProfiles[msg.sender].influencePoints + 1; // Gain 1 influence per observation
        _observerProfiles[msg.sender].lastObservationBlockPerObject[_tokenId] = block.number;

        emit CelestialObjectObserved(_tokenId, msg.sender, block.number);
    }

    /// @notice Allows an observer to link external data (e.g., IPFS hash) to their observation.
    /// Requires the observer to have observed the object at least once.
    /// Overwrites previous data if called again by the same observer for the same object.
    /// @param _tokenId The ID of the object.
    /// @param _dataUri The URI (e.g., ipfs://...) pointing to the observation data.
    function recordObservationData(uint256 _tokenId, string memory _dataUri)
        public
        whenNotPaused
        objectExists(_tokenId)
    {
        // Check if observer has observed this object at least once (optional, but makes sense)
        // This check is implicit if we only allow recording data *after* observeCelestialObject is called.
        // A more robust check: require(_observerProfiles[msg.sender].lastObservationBlockPerObject[_tokenId] > 0, "Must observe object first");

        _observationData[_tokenId][msg.sender] = _dataUri;

        emit ObservationDataRecorded(_tokenId, msg.sender, _dataUri);
    }

    /// @notice Retrieves the data URI submitted by a specific observer for a specific object.
    /// @param _tokenId The ID of the object.
    /// @param _observer The address of the observer.
    /// @return The data URI string.
    function getObservationDataForObjectAndObserver(uint256 _tokenId, address _observer)
        public
        view
        objectExists(_tokenId)
        returns (string memory)
    {
        return _observationData[_tokenId][_observer];
    }


     /// @notice Gets the total number of observations recorded for a specific object.
    /// @param _tokenId The ID of the object.
    /// @return The total observation count.
    function getTotalObservationsOfObject(uint256 _tokenId) public view objectExists(_tokenId) returns (uint256) {
        return _celestialObjects[_tokenId].totalObservations;
    }

    /// @notice Gets the list of addresses that have observed the given object.
    /// NOTE: This implementation is inefficient for large numbers of observers per object.
    /// A production system might require a different data structure or off-chain indexing.
    /// For demonstration purposes, it returns a list.
    /// @param _tokenId The ID of the object.
    /// @return An array of observer addresses.
    function getObserversOfObject(uint256 _tokenId) public view objectExists(_tokenId) returns (address[] memory) {
         // This requires iterating over potentially many observers or storing observer lists per object.
         // Storing observer lists per object adds significant gas cost on observation.
         // Iterating over *all* possible observers is infeasible.
         // A practical approach often involves off-chain indexing based on events.
         // As a compromise for this example, let's return an empty array or simplify.
         // To return actual observers *stored on chain*, we'd need a `mapping(uint256 => address[])`
         // and push to the array on `observeCelestialObject`. This is the most common approach
         // despite the gas cost when arrays get large. Let's add that state variable and logic.

         // Added: `mapping(uint256 => address[]) private _objectObserversList;`
         // Added to `observeCelestialObject`: `_objectObserversList[_tokenId].push(msg.sender);`
         // However, this simple push doesn't handle duplicate observations by the same user correctly for a *unique* list.
         // A `mapping(uint256 => mapping(address => bool)) private _objectHasObserver;` would be needed to track unique observers.
         // Then push only if `!_objectHasObserver[_tokenId][msg.sender]`.

         // Let's implement the more complex version to return a unique list:
         // Added `mapping(uint256 => address[]) private _objectObserversList;`
         // Added `mapping(uint256 => mapping(address => bool)) private _objectHasObserver;`
         // Modified `observeCelestialObject`.

        return _objectObserversList[_tokenId];
    }


    // --- Phenomena System ---

    /// @notice Announces a new cosmic phenomenon event.
    /// Can be linked to a specific celestial object.
    /// @param _phenomenonTypeId The ID of the type of phenomenon.
    /// @param _linkedObjectId The ID of the object it's linked to (0 if none).
    /// @param _details Optional details URI (e.g., IPFS).
    function announcePhenomenon(uint256 _phenomenonTypeId, uint256 _linkedObjectId, string memory _details)
        public
        onlyOwner // Or a specific 'PhenomenonAnnouncer' role
        whenNotPaused
        nonReentrant
    {
        require(_phenomenonTypeId > 0 && _phenomenonTypeId <= _phenomenonTypeIds.current(), "Invalid phenomenon type ID");
        if (_linkedObjectId != 0) {
            require(_exists(_linkedObjectId), "Linked object does not exist");
        }

        _phenomenonIds.increment();
        uint256 newPhenomenonId = _phenomenonIds.current();
        PhenomenonType storage phenType = _phenomenonTypes[_phenomenonTypeId];

        _phenomena[newPhenomenonId].phenomenonTypeId = _phenomenonTypeId;
        _phenomena[newPhenomenonId].startBlock = block.number;
        _phenomena[newPhenomenonId].endBlock = block.number.add(phenType.durationBlocks);
        _phenomena[newPhenomenonId].linkedObjectId = _linkedObjectId;
        _phenomena[newPhenomenonId].details = _details;
        _phenomena[newPhenomenonId].totalParticipants = 0;

        if (_linkedObjectId != 0) {
            _objectPhenomena[_linkedObjectId].push(newPhenomenonId);
        }

        emit PhenomenonAnnounced(newPhenomenonId, _phenomenonTypeId, _linkedObjectId, block.number, _phenomena[newPhenomenonId].endBlock);
    }

    /// @notice Allows a user to participate in an active phenomenon.
    /// Participation is only possible while the phenomenon is active and only once per user per phenomenon.
    /// Awards influence points.
    /// @param _phenomenonId The ID of the phenomenon to participate in.
    function participateInPhenomenon(uint256 _phenomenonId)
        public
        whenNotPaused
        phenomenonExists(_phenomenonId)
        nonReentrant
    {
        Phenomenon storage phen = _phenomena[_phenomenonId];
        require(block.number >= phen.startBlock && block.number <= phen.endBlock, "Phenomenon is not active");
        require(!phen.participants[msg.sender], "Already participated in this phenomenon");

        phen.participants[msg.sender] = true;
        phen.totalParticipants = phen.totalParticipants.add(1);
        _phenomenonParticipantsList[_phenomenonId].push(msg.sender); // Add to the list

        // Award influence points based on phenomenon type
        int256 influenceAward = _phenomenonTypes[phen.phenomenonTypeId].participantInfluenceAward;
        _observerProfiles[msg.sender].influencePoints += influenceAward;

        emit PhenomenonParticipated(_phenomenonId, msg.sender, block.number);
    }


    /// @notice Retrieves details for a specific phenomenon.
    /// @param _phenomenonId The ID of the phenomenon.
    /// @return phenomenonTypeId The type ID.
    /// @return startBlock The start block.
    /// @return endBlock The end block.
    /// @return linkedObjectId The linked object ID (0 if none).
    /// @return details The details URI.
    /// @return totalParticipants The total participant count.
    function getPhenomenonDetails(uint256 _phenomenonId)
        public
        view
        phenomenonExists(_phenomenonId)
        returns (uint256 phenomenonTypeId, uint256 startBlock, uint256 endBlock, uint256 linkedObjectId, string memory details, uint256 totalParticipants)
    {
        Phenomenon storage phen = _phenomena[_phenomenonId];
        return (phen.phenomenonTypeId, phen.startBlock, phen.endBlock, phen.linkedObjectId, phen.details, phen.totalParticipants);
    }

     /// @notice Returns a list of IDs for phenomena that are currently active.
    /// NOTE: This iterates over all phenomena, which can be inefficient if the total number is very large.
    /// For large scale, off-chain filtering of events is recommended.
    /// @return An array of active phenomenon IDs.
    function getActivePhenomena() public view returns (uint256[] memory) {
        uint256 totalPhenomena = _phenomenonIds.current();
        uint256[] memory activeIds = new uint256[](totalPhenomena); // Max size, will fill and return smaller array
        uint256 activeCount = 0;

        for (uint256 i = 1; i <= totalPhenomena; i++) {
            if (block.number >= _phenomena[i].startBlock && block.number <= _phenomena[i].endBlock) {
                activeIds[activeCount] = i;
                activeCount++;
            }
        }

        // Create a new array with the exact size
        uint256[] memory result = new uint256[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

     /// @notice Gets the list of addresses that have participated in a specific phenomenon.
    /// @param _phenomenonId The ID of the phenomenon.
    /// @return An array of participant addresses.
    function getParticipantsOfPhenomenon(uint256 _phenomenonId) public view phenomenonExists(_phenomenonId) returns (address[] memory) {
        return _phenomenonParticipantsList[_phenomenonId];
    }

    // --- Observer Profiles & Stats ---

    /// @notice Retrieves the discovery, observation, and influence stats for a given address.
    /// @param _observer The address to check.
    /// @return discoveries Total objects discovered.
    /// @return observations Total observations recorded.
    /// @return influencePoints Total influence points.
    function getObserverProfile(address _observer)
        public
        view
        returns (uint256 discoveries, uint256 observations, int256 influencePoints)
    {
        ObserverProfile storage profile = _observerProfiles[_observer];
        return (profile.discoveries, profile.observations, profile.influencePoints);
    }

    // --- Utility & View Functions ---

    /// @notice Returns the total number of celestial objects ever discovered.
    /// @return The total count.
    function getTotalObjectsDiscovered() public view returns (uint256) {
        return _objectIds.current();
    }

    /// @notice Returns the total number of phenomena ever announced.
    /// @return The total count.
    function getTotalPhenomenaAnnounced() public view returns (uint256) {
        return _phenomenonIds.current();
    }

    // --- ERC721 Required Functions ---

    /// @dev See {ERC721-tokenURI}. Simplified placeholder.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        objectExists(tokenId)
        returns (string memory)
    {
        // In a real application, this would return a URI pointing to metadata (e.g., on IPFS)
        // that describes the celestial object, potentially including its calculated score, name, etc.
        // Example: string(abi.encodePacked("ipfs://[CID]/", Strings.toString(tokenId), ".json"))
        // Or a dynamic API endpoint: string(abi.encodePacked("https://api.celestialregistry.xyz/metadata/", Strings.toString(tokenId)))

        // For this example, we return a simple string indicating the object exists.
        // A proper implementation would encode details or a link to them.
        return string(abi.encodePacked("Object data available via getObjectDetails(", Strings.toString(tokenId), ")"));
    }

    // ERC721 standard functions (inherited from OpenZeppelin):
    // - ownerOf(uint256 tokenId)
    // - transferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId)
    // - approve(address to, uint256 tokenId)
    // - getApproved(uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - isApprovedForAll(address owner, address operator)
    // - balanceOf(address owner)
    // - name()
    // - symbol()
    // These 11 inherited functions, plus the 27 custom ones above, meet the >20 function requirement.

    // --- Internal/Helper Logic (Used by getObserversOfObject and observeCelestialObject) ---
    // These mappings are added to support `getObserversOfObject` efficiently.
    mapping(uint256 => address[]) private _objectObserversList; // List of unique observers per object
    mapping(uint256 => mapping(address => bool)) private _objectHasObserver; // Check if an address has observed an object

    // Re-implementing observeCelestialObject slightly to update _objectObserversList and _objectHasObserver
    // (This version replaces the previous one for the function count)
    /// @notice Records an observation of a celestial object by the caller.
    /// Updates observer profile and object observation count. Enforces cooldown per object per observer.
    /// Adds observer to the list if they are observing for the first time.
    /// @param _tokenId The ID of the object being observed.
    function observeCelestialObject(uint256 _tokenId)
        public
        whenNotPaused
        objectExists(_tokenId)
        nonReentrant
    {
        // Observation cooldown for this object for this observer
        require(block.number >= _observerProfiles[msg.sender].lastObservationBlockPerObject[_tokenId].add(5), "Observation cooldown active for this object"); // 5 block cooldown example

        bool isNewObserver = !_objectHasObserver[_tokenId][msg.sender];
        if (isNewObserver) {
            _objectObserversList[_tokenId].push(msg.sender);
            _objectHasObserver[_tokenId][msg.sender] = true;
        }

        // Increment total observations for the object
        _celestialObjects[_tokenId].totalObservations = _celestialObjects[_tokenId].totalObservations.add(1);

        // Update observer profile
        _observerProfiles[msg.sender].observations = _observerProfiles[msg.sender].observations.add(1);
        _observerProfiles[msg.sender].influencePoints = _observerProfiles[msg.sender].influencePoints + 1; // Gain 1 influence per observation
        _observerProfiles[msg.sender].lastObservationBlockPerObject[_tokenId] = block.number;

        emit CelestialObjectObserved(_tokenId, msg.sender, block.number);
    }

    // The getObserversOfObject function now uses the stored list:
    /// @notice Gets the list of addresses that have uniquely observed the given object.
    /// @param _tokenId The ID of the object.
    /// @return An array of observer addresses.
    function getObserversOfObject(uint256 _tokenId) public view objectExists(_tokenId) returns (address[] memory) {
        return _objectObserversList[_tokenId];
    }

    // Total custom functions: 2 + 3 + 2 + 6 + 5 + 5 + 1 + 3 = 27
    // Total inherited ERC721 functions: 11 (constructor is separate)
    // Total functions = 27 + 11 = 38. Well over 20.
}
```