Okay, let's create a smart contract concept around a dynamic, evolving "Digital Soul Echo" – a non-transferable, on-chain identity layer that accrues attributes, memories, and connections based on interaction. It's inspired by Soulbound Tokens but focuses on the *data* and its evolution rather than just the token standard. It incorporates concepts of statefulness, time-based changes, simple social graph building, and configurable attributes.

Here is the smart contract code with the outline and function summary.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DigitalSoulEcho
 * @dev A contract for managing dynamic, non-transferable digital identities ("Souls")
 * bound to specific addresses. Souls evolve over time, accumulate attributes,
 * memories, and connections based on interactions, and have configurable properties.
 */

// --- OUTLINE ---
// 1. Contract Description & Concept
// 2. State Variables
// 3. Structs
// 4. Events
// 5. Modifiers
// 6. Owner Functions (Configuration)
// 7. Soul Management Functions (Claiming, Evolution)
// 8. Soul Data Interaction Functions (Attributes, Memories, Emotions, Description)
// 9. Soul Connection Functions
// 10. Interaction Logging Functions
// 11. Delegation Functions (Memory Access)
// 12. Scoring and State Functions
// 13. View Functions (Reading Data)

// --- FUNCTION SUMMARY ---
// Config/Owner Functions:
// - setAttributeConfig: Sets min, max, default, and decay rate for an attribute.
// - setAllowedInteractionType: Adds a type of interaction that can be logged.
// - removeAllowedInteractionType: Removes an allowed interaction type.
// - setSoulPhaseThresholds: Configures the timestamps that trigger soul phase changes.
// - setConnectionLimit: Sets the maximum number of connections a soul can have.
// - setMemoryLimit: Sets the maximum number of memories a soul can store.
// - getConfig: Retrieves current contract configuration.

// Soul Management/Evolution:
// - claimSoul: Allows an address to claim their unique Digital Soul Echo.
// - evolveSoul: Triggers the evolution process for a soul, applying decay, updating phase, etc. Can be called by anyone (gas costs apply).

// Soul Data Interaction:
// - updateAttribute: Changes the value of a soul's dynamic attribute within configured bounds.
// - addMemory: Adds a descriptive memory entry to a soul's history.
// - removeMemory: Allows a soul owner to remove a specific memory.
// - updateEmotionalResonance: Adjusts an emotional score for the soul.
// - setSoulDescription: Sets a short, free-text description for the soul.

// Soul Connections:
// - establishConnection: Creates a bidirectional link between two souls (if within limits).
// - removeConnection: Removes a connection between two souls.

// Interaction Logging:
// - logManualInteraction: Allows a soul owner to log a custom interaction note.
// - logSystemInteraction: Internal function (or potentially callable by trusted entities/other contracts) to log predefined interaction types. (Designed to be called internally by other functions or specific privileged roles, demonstrated here as internal).

// Delegation (Memory Access):
// - delegateMemoryAccess: Allows a soul owner to grant another address read access to a specific memory.
// - revokeMemoryAccess: Revokes previously granted memory access.
// - canAccessMemory: Checks if an address has been delegated access to a specific memory.

// Scoring and State:
// - calculateSoulScore: Computes a composite score based on a soul's attributes, memories, connections, and age.
// - getSoulPhase: Determines the current evolutionary phase of a soul based on its age and configured thresholds.

// View Functions:
// - soulExists: Checks if an address has claimed a soul.
// - getSoulDetails: Retrieves all core details for a given soul.
// - getAttributes: Retrieves the attributes of a soul.
// - getMemories: Retrieves the memories of a soul.
// - getEmotionalResonance: Retrieves the emotional resonance scores of a soul.
// - getConnections: Retrieves the connections of a soul.
// - getInteractionCount: Gets the count for a specific type of system interaction.
// - getManualInteractions: Retrieves the manually logged interactions for a soul.
// - getAttributeConfig: Retrieves the configuration for a specific attribute type.
// - getAllowedInteractionTypes: Retrieves the list of interaction types that can be logged.
// - getDelegatedMemoryAccess: Retrieves the memory indices delegated to a specific address by an owner.

contract DigitalSoulEcho {

    address private _owner;

    // --- State Variables ---

    // Mapping from soul owner address to their Soul data
    mapping(address => Soul) private souls;
    // Set of addresses that have claimed a soul
    mapping(address => bool) private hasSoul;

    // Configuration for different attribute types
    mapping(string => AttributeConfig) private attributeConfigs;
    // Set of allowed interaction types that can be logged
    mapping(string => bool) private allowedInteractionTypes;

    // Thresholds (in seconds) for soul phase evolution (e.g., Nascent, Developing, Mature)
    // soulPhaseThresholds[0] = duration for phase 1, soulPhaseThresholds[1] = duration for phase 2, etc.
    uint256[] private soulPhaseThresholds;

    // Limits
    uint256 private connectionLimit = 10; // Default connection limit per soul
    uint256 private memoryLimit = 50;    // Default memory limit per soul

    // Delegation: owner => delegatee => set of memory indices
    mapping(address => mapping(address => mapping(uint256 => bool))) private delegatedMemoryAccess;
    // To make retrieving delegated memories easier: owner => delegatee => list of indices
     mapping(address => mapping(address => uint256[])) private delegatedMemoryIndicesList;


    // --- Structs ---

    struct AttributeConfig {
        int256 minValue;
        int256 maxValue;
        int256 defaultValue;
        uint256 decayRatePerSecond; // Amount to decay per second (scaled by 1e18 for fixed point)
        bool configured; // Indicates if the attribute type has been configured
    }

    struct MemoryEntry {
        uint256 timestamp;
        string description;
        address relatedAddress; // Optional: address related to the memory
    }

    struct Soul {
        uint256 claimTimestamp;
        uint256 lastEvolvedTimestamp;
        mapping(string => int256) attributes; // Dynamic attributes (e.g., Curiosity, Stoicism)
        mapping(string => int256) emotionalResonance; // Abstract emotional scores (e.g., Joy, Sorrow)
        MemoryEntry[] memories;
        address[] connections;
        mapping(string => uint256) interactionCounts; // Counts for predefined interaction types
        string[] manualInteractions; // User-added interaction notes
        string description; // Short free-text description
    }

    // --- Events ---

    event SoulClaimed(address indexed owner, uint256 timestamp);
    event SoulEvolved(address indexed owner, uint256 timestamp, string newPhase);
    event AttributeUpdated(address indexed owner, string attributeName, int256 newValue, int256 valueChange);
    event MemoryAdded(address indexed owner, uint256 timestamp, uint256 memoryIndex);
    event MemoryRemoved(address indexed owner, uint256 memoryIndex);
    event ConnectionEstablished(address indexed soul1, address indexed soul2, uint256 timestamp);
    event ConnectionRemoved(address indexed soul1, address indexed soul2, uint256 timestamp);
    event EmotionalResonanceUpdated(address indexed owner, string emotion, int256 newValue, int256 valueChange);
    event SoulDescriptionUpdated(address indexed owner, string description);
    event ManualInteractionLogged(address indexed owner, uint256 timestamp, string note);
    event SystemInteractionLogged(address indexed owner, string interactionType, uint256 count);
    event MemoryAccessDelegated(address indexed owner, address indexed delegatee, uint256 memoryIndex);
    event MemoryAccessRevoked(address indexed owner, address indexed delegatee, uint256 memoryIndex);
    event AttributeConfigUpdated(string attributeName, AttributeConfig config);
    event AllowedInteractionTypeAdded(string interactionType);
    event AllowedInteractionTypeRemoved(string interactionType);
    event SoulPhaseThresholdsUpdated(uint256[] thresholds);
    event ConnectionLimitUpdated(uint256 limit);
    event MemoryLimitUpdated(uint256 limit);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier soulExists(address _address) {
        require(hasSoul[_address], "Soul does not exist for this address");
        _;
    }

    modifier onlySoulOwner(address _owner) {
        require(msg.sender == _owner, "Only soul owner can call this function");
        _;
    }

    modifier attributeConfigExists(string memory _attributeName) {
        require(attributeConfigs[_attributeName].configured, "Attribute config does not exist");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        // Set some initial default phase thresholds (e.g., 1 day, 7 days, 30 days)
        soulPhaseThresholds = [1 days, 7 days, 30 days];
         // Set initial attribute configs (example)
        setAttributeConfig("Curiosity", 0, 100, 50, 0); // 0 decay
        setAttributeConfig("Stoicism", 0, 100, 50, 0); // 0 decay
        setAttributeConfig("Empathy", 0, 100, 50, 1e18 / (30 days)); // Decays over time
        setAttributeConfig("Resilience", 0, 100, 50, 1e18 / (60 days)); // Decays slower
        // Set initial allowed interaction types (example)
        allowedInteractionTypes["TransferSent"] = true; // Could be logged if integrated with external transfer hooks
        allowedInteractionTypes["TransferReceived"] = true; // Could be logged
        allowedInteractionTypes["ContractDeployed"] = true; // Could be logged
        allowedInteractionTypes["InteractedWithDAO"] = true; // Could be logged
    }

    // --- Owner Functions (Configuration) ---

    /**
     * @dev Sets or updates configuration for a dynamic attribute type.
     * @param _attributeName The name of the attribute.
     * @param _minValue The minimum allowed value.
     * @param _maxValue The maximum allowed value.
     * @param _defaultValue The default value when a soul is claimed.
     * @param _decayRatePerSecond The rate at which the attribute decays per second (scaled by 1e18).
     */
    function setAttributeConfig(
        string memory _attributeName,
        int256 _minValue,
        int256 _maxValue,
        int256 _defaultValue,
        uint256 _decayRatePerSecond
    ) public onlyOwner {
        require(_minValue <= _maxValue, "Min value cannot be greater than max value");
        require(_defaultValue >= _minValue && _defaultValue <= _maxValue, "Default value must be within bounds");

        attributeConfigs[_attributeName] = AttributeConfig({
            minValue: _minValue,
            maxValue: _maxValue,
            defaultValue: _defaultValue,
            decayRatePerSecond: _decayRatePerSecond,
            configured: true
        });

        emit AttributeConfigUpdated(_attributeName, attributeConfigs[_attributeName]);
    }

    /**
     * @dev Adds a type of interaction that can be logged via logSystemInteraction.
     * @param _interactionType The name of the interaction type.
     */
    function setAllowedInteractionType(string memory _interactionType) public onlyOwner {
        allowedInteractionTypes[_interactionType] = true;
        emit AllowedInteractionTypeAdded(_interactionType);
    }

    /**
     * @dev Removes an allowed interaction type.
     * @param _interactionType The name of the interaction type.
     */
    function removeAllowedInteractionType(string memory _interactionType) public onlyOwner {
         delete allowedInteractionTypes[_interactionType];
         emit AllowedInteractionTypeRemoved(_interactionType);
    }

    /**
     * @dev Sets the thresholds (in seconds from claim time) for soul phase changes.
     * @param _thresholds An array of durations in seconds.
     */
    function setSoulPhaseThresholds(uint256[] memory _thresholds) public onlyOwner {
        // Optional: Add check for sorted thresholds
        soulPhaseThresholds = _thresholds;
        emit SoulPhaseThresholdsUpdated(_thresholds);
    }

    /**
     * @dev Sets the maximum number of connections a soul can establish.
     * @param _limit The new connection limit.
     */
    function setConnectionLimit(uint256 _limit) public onlyOwner {
        connectionLimit = _limit;
        emit ConnectionLimitUpdated(_limit);
    }

     /**
     * @dev Sets the maximum number of memories a soul can store.
     * @param _limit The new memory limit.
     */
    function setMemoryLimit(uint256 _limit) public onlyOwner {
        memoryLimit = _limit;
        emit MemoryLimitUpdated(_limit);
    }


    /**
     * @dev Retrieves the current configuration settings.
     */
    function getConfig() public view onlyOwner returns (uint256[] memory _soulPhaseThresholds, uint256 _connectionLimit, uint256 _memoryLimit) {
        return (soulPhaseThresholds, connectionLimit, memoryLimit);
    }


    // --- Soul Management Functions ---

    /**
     * @dev Allows the caller to claim their unique Digital Soul Echo.
     * A soul can only be claimed once per address.
     */
    function claimSoul() public {
        require(!hasSoul[msg.sender], "Soul already claimed");

        Soul storage newSoul = souls[msg.sender];
        newSoul.claimTimestamp = block.timestamp;
        newSoul.lastEvolvedTimestamp = block.timestamp;

        // Initialize attributes with default values if configured
        // NOTE: Iterating over all possible attribute names is not possible on-chain.
        // Attribute names must be known or set via config functions prior to claim.
        // For demonstration, let's assume some are pre-configured in constructor/config.
        // A real system might require listing default attributes explicitly or
        // initializing them upon first interaction.
        // We'll just rely on the default value lookup when attributes are first updated.

        hasSoul[msg.sender] = true;

        emit SoulClaimed(msg.sender, block.timestamp);
    }

    /**
     * @dev Triggers the evolution process for a soul.
     * This function applies decay to attributes, updates the soul's phase, etc.
     * Callable by anyone, but typically by the soul owner or an incentivized service.
     * @param _soulOwner The address of the soul to evolve.
     */
    function evolveSoul(address _soulOwner) public soulExists(_soulOwner) {
        Soul storage soul = souls[_soulOwner];
        uint256 timeElapsed = block.timestamp - soul.lastEvolvedTimestamp;

        // Apply Attribute Decay
        // NOTE: Applying decay to *all* potential attributes requires iterating over
        // configured attributes, which is hard on-chain. A realistic implementation
        // might only decay attributes that are accessed/updated, or require a separate
        // owner/service call to decay specific attributes or batches.
        // For simplicity here, let's assume a limited set of attributes configured
        // in the constructor are checked for decay.
        // A more scalable approach would store an iterable list of attribute names
        // in the config or only decay attributes that are explicitly updated or read.
        // Demonstrating decay for pre-defined attributes:
        _applyDecay(_soulOwner, "Empathy", timeElapsed);
        _applyDecay(_soulOwner, "Resilience", timeElapsed);
        // ... potentially others added via setAttributeConfig ...


        // Update Soul Phase
        string memory oldPhase = getSoulPhase(_soulOwner);
        string memory newPhase = _calculateSoulPhase(_soulOwner);
        if (keccak256(abi.encodePacked(oldPhase)) != keccak256(abi.encodePacked(newPhase))) {
             // Phase isn't stored, it's calculated, but we can emit an event when it *would* change based on time.
             // Or, we could store phase if we had more complex phase transition logic than just time.
        }

        soul.lastEvolvedTimestamp = block.timestamp;
        emit SoulEvolved(_soulOwner, block.timestamp, newPhase); // Emit the new calculated phase
    }

    /**
     * @dev Internal helper to apply decay to a specific attribute.
     */
    function _applyDecay(address _soulOwner, string memory _attributeName, uint256 _timeElapsed) internal {
        AttributeConfig storage config = attributeConfigs[_attributeName];
         // Only apply decay if attribute is configured and has decay rate
        if (config.configured && config.decayRatePerSecond > 0 && _timeElapsed > 0) {
            Soul storage soul = souls[_soulOwner];
            // Decay amount = rate * time elapsed
            // Scale decay rate by 1e18 if using fixed point, or adjust based on uint scaling
            // Using 1e18 scaling for potential fractional decay rates
            uint256 decayAmountScaled = config.decayRatePerSecond * _timeElapsed;
            // Convert scaled decay amount to integer decay amount
            // This involves division, losing precision. For more precision, use a fixed-point library or track remainder.
             int256 decayAmount = int256(decayAmountScaled / (1e18)); // Integer part of decay

            // Ensure decay doesn't push value below min
            int256 currentValue = soul.attributes[_attributeName];
            int256 newValue = currentValue - decayAmount;
            if (newValue < config.minValue) {
                newValue = config.minValue;
            }

            if (newValue != currentValue) {
                 soul.attributes[_attributeName] = newValue;
                 // No event emitted here to save gas, event is from updateAttribute if called directly
            }
        }
    }


    // --- Soul Data Interaction Functions ---

    /**
     * @dev Updates the value of a soul's dynamic attribute.
     * Ensures the new value stays within the configured min/max bounds.
     * @param _attributeName The name of the attribute to update.
     * @param _valueChange The amount to add to the current attribute value (can be negative).
     */
    function updateAttribute(string memory _attributeName, int256 _valueChange)
        public soulExists(msg.sender) attributeConfigExists(_attributeName)
    {
        Soul storage soul = souls[msg.sender];
        AttributeConfig storage config = attributeConfigs[_attributeName];

        int256 currentValue = soul.attributes[_attributeName];
        int256 newValue;

        // If attribute hasn't been set yet, use default value before applying change
        // A more robust check might involve a separate mapping `hasAttribute` or a sentinel value
         if (currentValue == 0 && _valueChange != 0 && config.defaultValue != 0) {
             // Simple check: if current value is 0 and default is non-zero, assume it hasn't been initialized
             // This is a simplification. A proper check would be needed.
             // For now, let's just apply change directly, relying on default being 0 if not set.
             // Better: initialize all known attributes to defaults upon claim? Gas cost!
             // Let's assume attributes default to 0 if not set.

            // If _valueChange is positive, check for overflow relative to maxValue
            if (_valueChange > 0) {
                 int256 maxIncrease = config.maxValue - currentValue;
                 if (_valueChange > maxIncrease) {
                     newValue = config.maxValue;
                 } else {
                     newValue = currentValue + _valueChange;
                 }
            }
            // If _valueChange is negative, check for underflow relative to minValue
            else { // _valueChange <= 0
                 int256 maxDecrease = currentValue - config.minValue;
                 if (_valueChange < -maxDecrease) { // _valueChange is negative, so -maxDecrease is more negative
                      newValue = config.minValue;
                 } else {
                      newValue = currentValue + _valueChange;
                 }
            }

         } else {
             // Regular update logic applying change and bounds
              if (_valueChange > 0) {
                 int256 maxIncrease = config.maxValue - currentValue;
                 if (_valueChange > maxIncrease) {
                     newValue = config.maxValue;
                 } else {
                     newValue = currentValue + _valueChange;
                 }
            }
            else { // _valueChange <= 0
                 int256 maxDecrease = currentValue - config.minValue;
                 if (_valueChange < -maxDecrease) {
                      newValue = config.minValue;
                 } else {
                      newValue = currentValue + _valueChange;
                 }
            }
         }


        soul.attributes[_attributeName] = newValue;

        emit AttributeUpdated(msg.sender, _attributeName, newValue, _valueChange);
    }

    /**
     * @dev Adds a memory entry to the soul's history.
     * There is a configured limit on the number of memories.
     * @param _description A string describing the memory.
     * @param _relatedAddress An optional address related to the memory.
     */
    function addMemory(string memory _description, address _relatedAddress)
        public soulExists(msg.sender)
    {
        Soul storage soul = souls[msg.sender];
        require(soul.memories.length < memoryLimit, "Memory limit reached");

        soul.memories.push(MemoryEntry({
            timestamp: block.timestamp,
            description: _description,
            relatedAddress: _relatedAddress
        }));

        emit MemoryAdded(msg.sender, block.timestamp, soul.memories.length - 1);
    }

    /**
     * @dev Allows the soul owner to remove a memory entry by its index.
     * Be cautious with array index removal in Solidity regarding gas costs and index shifting.
     * This implementation uses the swap-and-pop method to maintain a dense array,
     * which changes the order but is gas-efficient for removal.
     * @param _memoryIndex The index of the memory to remove.
     */
    function removeMemory(uint256 _memoryIndex) public soulExists(msg.sender) onlySoulOwner(msg.sender) {
        Soul storage soul = souls[msg.sender];
        require(_memoryIndex < soul.memories.length, "Memory index out of bounds");

        // Swap the element to remove with the last element
        if (_memoryIndex != soul.memories.length - 1) {
            soul.memories[_memoryIndex] = soul.memories[soul.memories.length - 1];
            // Need to update delegation mappings if memory was delegated
            // This is complex as we don't know who it was delegated *to*.
            // A better delegation approach might be needed if frequent removal is expected,
            // or just clear *all* delegations for the removed index? Clearing all is simpler but perhaps too broad.
            // Let's add a note: removing memories may invalidate delegations.
            // Or, better, when removing, iterate through all potential delegatees and remove that index?
            // This is too gas intensive. Simplest is to make removal rare or state that removing invalidates access.
            // Or, delegation should use a memory ID, not an index? Memory IDs could be timestamps+index at creation?
            // Let's stick to index for now and note the complexity/limitation with delegation.
        }

        // Remove the last element
        soul.memories.pop();

        emit MemoryRemoved(msg.sender, _memoryIndex);
    }

    /**
     * @dev Adjusts the value of an abstract emotional resonance score for the soul.
     * @param _emotion The name of the emotion (e.g., "Joy", "Sorrow").
     * @param _valueChange The amount to add to the current emotional score (can be negative).
     */
    function updateEmotionalResonance(string memory _emotion, int256 _valueChange)
        public soulExists(msg.sender)
    {
        Soul storage soul = souls[msg.sender];
        int256 currentValue = soul.emotionalResonance[_emotion];
        int256 newValue = currentValue + _valueChange;
        // Optional: add bounds for emotional resonance too?

        soul.emotionalResonance[_emotion] = newValue;

        emit EmotionalResonanceUpdated(msg.sender, _emotion, newValue, _valueChange);
    }

    /**
     * @dev Sets a short, free-text description for the soul.
     * Consider length limits to avoid excessive gas costs for storage.
     * @param _description The new description string.
     */
    function setSoulDescription(string memory _description) public soulExists(msg.sender) onlySoulOwner(msg.sender) {
         // Optional: Add length check for _description
         souls[msg.sender].description = _description;
         emit SoulDescriptionUpdated(msg.sender, _description);
    }


    // --- Soul Connection Functions ---

    /**
     * @dev Establishes a bidirectional connection between the caller's soul and another soul.
     * Connections are limited per soul.
     * @param _otherSoul The address of the soul to connect to.
     */
    function establishConnection(address _otherSoul)
        public soulExists(msg.sender) soulExists(_otherSoul)
    {
        require(msg.sender != _otherSoul, "Cannot connect soul to itself");

        Soul storage mySoul = souls[msg.sender];
        Soul storage otherSoul = souls[_otherSoul];

        require(mySoul.connections.length < connectionLimit, "Caller's soul connection limit reached");
        require(otherSoul.connections.length < connectionLimit, "Other soul's connection limit reached");

        // Check if already connected (requires iterating connections array - O(N) gas cost)
        bool alreadyConnected = false;
        for (uint i = 0; i < mySoul.connections.length; i++) {
            if (mySoul.connections[i] == _otherSoul) {
                alreadyConnected = true;
                break;
            }
        }
        require(!alreadyConnected, "Souls are already connected");

        // Add connection to both souls
        mySoul.connections.push(_otherSoul);
        otherSoul.connections.push(msg.sender);

        emit ConnectionEstablished(msg.sender, _otherSoul, block.timestamp);
    }

     /**
     * @dev Removes a connection between the caller's soul and another soul.
     * Requires iterating and removing from both connection arrays (O(N) gas cost).
     * @param _otherSoul The address of the soul to disconnect from.
     */
    function removeConnection(address _otherSoul)
        public soulExists(msg.sender) soulExists(_otherSoul) onlySoulOwner(msg.sender)
    {
         Soul storage mySoul = souls[msg.sender];
         Soul storage otherSoul = souls[_otherSoul];

         bool removed = false;
         // Find and remove from caller's connections
         for (uint i = 0; i < mySoul.connections.length; i++) {
             if (mySoul.connections[i] == _otherSoul) {
                 // Swap with last and pop (changes order)
                 if (i != mySoul.connections.length - 1) {
                     mySoul.connections[i] = mySoul.connections[mySoul.connections.length - 1];
                 }
                 mySoul.connections.pop();
                 removed = true;
                 break; // Assume max one connection per pair
             }
         }

         require(removed, "Connection does not exist");

         // Find and remove from other soul's connections
         for (uint i = 0; i < otherSoul.connections.length; i++) {
             if (otherSoul.connections[i] == msg.sender) {
                 // Swap with last and pop
                 if (i != otherSoul.connections.length - 1) {
                     otherSoul.connections[i] = otherSoul.connections[otherSoul.connections.length - 1];
                 }
                 otherSoul.connections.pop();
                 break; // Assume max one connection per pair
             }
         }

         emit ConnectionRemoved(msg.sender, _otherSoul, block.timestamp);
    }


    // --- Interaction Logging Functions ---

    /**
     * @dev Allows the soul owner to log a custom note about an interaction.
     * @param _note The string note about the interaction.
     */
    function logManualInteraction(string memory _note) public soulExists(msg.sender) onlySoulOwner(msg.sender) {
        Souls storage soul = souls[msg.sender];
        soul.manualInteractions.push(_note); // Consider length limits here too

        emit ManualInteractionLogged(msg.sender, block.timestamp, _note);
    }

    /**
     * @dev Internal function to log predefined system interaction types.
     * Designed to be called by other internal functions or potentially privileged external systems.
     * Not directly exposed as public to prevent arbitrary logging without checks.
     * @param _soulOwner The address of the soul to log interaction for.
     * @param _interactionType The type of interaction (must be allowed).
     */
    function logSystemInteraction(address _soulOwner, string memory _interactionType) internal soulExists(_soulOwner) {
         require(allowedInteractionTypes[_interactionType], "Interaction type not allowed");

         Soul storage soul = souls[_soulOwner];
         soul.interactionCounts[_interactionType]++;

         emit SystemInteractionLogged(_soulOwner, _interactionType, soul.interactionCounts[_interactionType]);
    }


    // --- Delegation Functions (Memory Access) ---

    /**
     * @dev Allows the soul owner to grant read access of a specific memory entry
     * to another address (delegatee).
     * Uses the memory index. Removing memories may invalidate delegations.
     * @param _delegatee The address to grant access to.
     * @param _memoryIndex The index of the memory to delegate.
     */
    function delegateMemoryAccess(address _delegatee, uint256 _memoryIndex)
        public soulExists(msg.sender) onlySoulOwner(msg.sender)
    {
        Soul storage soul = souls[msg.sender];
        require(_memoryIndex < soul.memories.length, "Memory index out of bounds");
        require(_delegatee != address(0) && _delegatee != msg.sender, "Invalid delegatee address");

        if (!delegatedMemoryAccess[msg.sender][_delegatee][_memoryIndex]) {
            delegatedMemoryAccess[msg.sender][_delegatee][_memoryIndex] = true;
             // Add to the list for easier retrieval
            delegatedMemoryIndicesList[msg.sender][_delegatee].push(_memoryIndex);
            emit MemoryAccessDelegated(msg.sender, _delegatee, _memoryIndex);
        }
        // Else: already delegated, do nothing
    }

    /**
     * @dev Revokes previously granted read access for a specific memory entry.
     * @param _delegatee The address whose access to revoke.
     * @param _memoryIndex The index of the memory.
     */
    function revokeMemoryAccess(address _delegatee, uint256 _memoryIndex)
         public soulExists(msg.sender) onlySoulOwner(msg.sender)
    {
         require(_delegatee != address(0) && _delegatee != msg.sender, "Invalid delegatee address");
         require(delegatedMemoryAccess[msg.sender][_delegatee][_memoryIndex], "Memory access not delegated");

         delete delegatedMemoryAccess[msg.sender][_delegatee][_memoryIndex];

         // Remove from the list - expensive O(N) operation
         uint256[] storage indicesList = delegatedMemoryIndicesList[msg.sender][_delegatee];
         for (uint i = 0; i < indicesList.length; i++) {
             if (indicesList[i] == _memoryIndex) {
                 // Swap with last and pop
                 if (i != indicesList.length - 1) {
                     indicesList[i] = indicesList[indicesList.length - 1];
                 }
                 indicesList.pop();
                 break;
             }
         }

         emit MemoryAccessRevoked(msg.sender, _delegatee, _memoryIndex);
    }

    /**
     * @dev Checks if an address has been delegated access to a specific memory index
     * by the soul owner.
     * @param _owner The address of the soul owner.
     * @param _delegatee The address checking for access.
     * @param _memoryIndex The index of the memory.
     * @return bool True if access is delegated, false otherwise.
     */
    function canAccessMemory(address _owner, address _delegatee, uint256 _memoryIndex)
         public view soulExists(_owner) returns (bool)
    {
         // Soul owner always has access
         if (_delegatee == _owner) {
             return true;
         }
         // Check delegation mapping
         return delegatedMemoryAccess[_owner][_delegatee][_memoryIndex];
    }


    // --- Scoring and State Functions ---

     /**
     * @dev Calculates a composite score for a soul based on its attributes,
     * memory count, connection count, and age.
     * The scoring logic is a simple example and can be complex.
     * @param _soulOwner The address of the soul to score.
     * @return uint256 The calculated soul score.
     */
    function calculateSoulScore(address _soulOwner) public view soulExists(_soulOwner) returns (uint256) {
        Soul storage soul = souls[_soulOwner];
        uint256 score = 0;

        // Score based on attributes (positive values add, negative subtract)
        // NOTE: This requires iterating over all *configured* attributes to be accurate,
        // which is not directly feasible on-chain without an iterable list of attribute names.
        // For a realistic contract, attribute scores would need to be updated incrementally
        // or use a different storage pattern.
        // Example: Sum up a few known attribute scores - simplified!
        score += uint256(_getValueOrZero(soul.attributes["Curiosity"]));
        score += uint256(_getValueOrZero(soul.attributes["Stoicism"]));
        // Be careful with negative values: maybe absolute value or only score positive emotions?
        // For simplicity, let's add positive emotions and subtract negative ones.
         score += uint256(int256(uint256(_getValueOrZero(soul.emotionalResonance["Joy"])))); // Add positive
         score -= uint256(int256(uint256(_getValueOrZero(soul.emotionalResonance["Sorrow"])))); // Subtract positive part of negative

        // Score based on memories and connections
        score += soul.memories.length * 5; // 5 points per memory
        score += soul.connections.length * 10; // 10 points per connection

        // Score based on age (linear increase)
        uint256 soulAgeSeconds = block.timestamp - soul.claimTimestamp;
        score += soulAgeSeconds / (1 days); // 1 point per day of age

        // Ensure no underflow if using subtractions extensively (though uint256 prevents < 0)
        // Need careful logic if allowing score to go below zero logically before casting to uint.
        // A simple way is to ensure additions generally outweigh subtractions or use int256 internally.
        // For this example, simple additions/subtractions that *could* theoretically go below zero will wrap in uint256.
        // In production, use SafeMath or careful checks.

        return score;
    }

    // Helper function to get attribute/emotion value, treating unset as 0
    function _getValueOrZero(int256 value) internal pure returns (int256) {
        // In Solidity, int256 default is 0, so direct use is fine unless a specific "unset" value is needed.
        return value;
    }

     /**
     * @dev Calculates the current evolutionary phase of a soul based on its age
     * and the configured phase thresholds.
     * @param _soulOwner The address of the soul.
     * @return string The name of the soul phase.
     */
    function getSoulPhase(address _soulOwner) public view soulExists(_soulOwner) returns (string memory) {
        Soul storage soul = souls[_soulOwner];
        uint256 age = block.timestamp - soul.claimTimestamp;

        if (soulPhaseThresholds.length == 0 || age < soulPhaseThresholds[0]) {
            return "Nascent"; // Phase 0
        }

        for (uint i = 0; i < soulPhaseThresholds.length - 1; i++) {
            if (age >= soulPhaseThresholds[i] && age < soulPhaseThresholds[i+1]) {
                // Phase i + 1 (index 0 is phase 1, index 1 is phase 2, etc.)
                // Convert index to phase name (example names)
                if (i == 0) return "Developing";
                if (i == 1) return "Mature";
                if (i == 2) return "Ethereal"; // Example names
                 // For more phases, you'd need a mapping or array of names
                return string(abi.encodePacked("Phase ", uint256(i + 2)));
            }
        }

        // If age is greater than or equal to the last threshold
        return string(abi.encodePacked("Beyond Phase ", soulPhaseThresholds.length));
    }


    // --- View Functions ---

    /**
     * @dev Checks if an address has claimed a soul.
     * @param _address The address to check.
     * @return bool True if a soul exists, false otherwise.
     */
    function soulExists(address _address) public view returns (bool) {
        return hasSoul[_address];
    }

    /**
     * @dev Retrieves all core details for a given soul.
     * WARNING: Returning large arrays/mappings can hit gas limits for read calls (though views are free off-chain, tools might struggle).
     * Prefer specific getter functions for arrays if they can grow large.
     * @param _owner The address of the soul owner.
     * @return tuple A tuple containing soul details.
     */
    function getSoulDetails(address _owner)
        public view soulExists(_owner)
        returns (
            uint256 claimTimestamp,
            uint256 lastEvolvedTimestamp,
            string memory description,
            uint256 memoryCount,
            uint256 connectionCount,
            uint256 interactionTypesCount, // Count of different interaction types logged
            uint256 manualInteractionCount
        )
    {
        Soul storage soul = souls[_owner];
        return (
            soul.claimTimestamp,
            soul.lastEvolvedTimestamp,
            soul.description,
            soul.memories.length,
            soul.connections.length,
            0, // Cannot easily count mapping keys on-chain. Placeholder.
            soul.manualInteractions.length
        );
        // NOTE: Returning mappings or dynamic arrays directly from a single view function is inefficient
        // and can lead to "gas limit exceeded" even for view calls in some environments or block explorers.
        // Specific getter functions below are provided for arrays and mappings.
    }

    /**
     * @dev Retrieves the dynamic attributes of a soul.
     * NOTE: Cannot return the entire mapping directly. Must specify attribute names.
     * A workaround is to return a list of names and values for *known* attributes,
     * or require the caller to query attributes one by one.
     * This function provides values for a *pre-defined* list of attributes.
     * @param _owner The address of the soul.
     * @return tuple A tuple of attribute names and their values.
     */
    function getAttributes(address _owner)
        public view soulExists(_owner)
        returns (string[] memory names, int256[] memory values)
    {
        // This is a limitation. Must hardcode attribute names or manage an iterable list.
        // For this example, return values for the few attributes set in the constructor/config.
        names = new string[](4);
        values = new int256[](4);

        names[0] = "Curiosity"; values[0] = souls[_owner].attributes["Curiosity"];
        names[1] = "Stoicism"; values[1] = souls[_owner].attributes["Stoicism"];
        names[2] = "Empathy"; values[2] = souls[_owner].attributes["Empathy"];
        names[3] = "Resilience"; values[3] = souls[_owner].attributes["Resilience"];

        return (names, values);
    }

    /**
     * @dev Retrieves the memory entries for a soul.
     * WARNING: Can be gas-intensive for read calls if memory array grows large.
     * @param _owner The address of the soul.
     * @return MemoryEntry[] The array of memory entries.
     */
    function getMemories(address _owner)
        public view soulExists(_owner)
        returns (MemoryEntry[] memory)
    {
        // Direct return of dynamic array - can be inefficient for large arrays
        return souls[_owner].memories;
    }

     /**
     * @dev Retrieves the emotional resonance scores for a soul.
     * NOTE: Cannot return the entire mapping directly. Similar limitation to getAttributes.
     * Returns values for a *pre-defined* list of emotions.
     * @param _owner The address of the soul.
     * @return tuple A tuple of emotion names and their scores.
     */
    function getEmotionalResonance(address _owner)
        public view soulExists(_owner)
        returns (string[] memory names, int256[] memory values)
    {
        // This is a limitation. Must hardcode emotion names or manage an iterable list.
        names = new string[](2); // Example: Joy, Sorrow
        values = new int256[](2);

        names[0] = "Joy"; values[0] = souls[_owner].emotionalResonance["Joy"];
        names[1] = "Sorrow"; values[1] = souls[_owner].emotionalResonance["Sorrow"];

        return (names, values);
    }


    /**
     * @dev Retrieves the connections for a soul.
     * WARNING: Can be gas-intensive for read calls if connections array grows large.
     * @param _owner The address of the soul.
     * @return address[] The array of connected soul addresses.
     */
    function getConnections(address _owner)
        public view soulExists(_owner)
        returns (address[] memory)
    {
        // Direct return of dynamic array - can be inefficient for large arrays
        return souls[_owner].connections;
    }

    /**
     * @dev Gets the count for a specific type of system interaction for a soul.
     * @param _owner The address of the soul.
     * @param _interactionType The name of the interaction type.
     * @return uint256 The count of interactions.
     */
    function getInteractionCount(address _owner, string memory _interactionType)
        public view soulExists(_owner) returns (uint256)
    {
         return souls[_owner].interactionCounts[_interactionType];
    }

     /**
     * @dev Retrieves the manually logged interaction notes for a soul.
     * WARNING: Can be gas-intensive for read calls if manual interactions array grows large.
     * @param _owner The address of the soul.
     * @return string[] The array of manual interaction notes.
     */
    function getManualInteractions(address _owner)
        public view soulExists(_owner)
        returns (string[] memory)
    {
        // Direct return of dynamic array - can be inefficient for large arrays
        return souls[_owner].manualInteractions;
    }


    /**
     * @dev Retrieves the configuration details for a specific attribute type.
     * @param _attributeName The name of the attribute.
     * @return AttributeConfig The configuration struct.
     */
    function getAttributeConfig(string memory _attributeName)
        public view returns (AttributeConfig memory)
    {
        require(attributeConfigs[_attributeName].configured, "Attribute config does not exist");
        return attributeConfigs[_attributeName];
    }

    /**
     * @dev Retrieves the list of interaction types that are allowed to be logged.
     * NOTE: Iterating over mapping keys is not possible on-chain.
     * A separate state variable storing an array of allowed types would be needed for this.
     * This function is a placeholder demonstrating the intent; a real implementation
     * would require managing allowed types in an array.
     * @return string[] An array of allowed interaction type names (placeholder).
     */
    function getAllowedInteractionTypes() public view returns (string[] memory) {
        // This is a placeholder. Retrieving keys from a mapping is not possible.
        // A real implementation would need a separate array `string[] private _allowedInteractionTypes;`
        // updated alongside the mapping.
        revert("Cannot list mapping keys. Implement with an auxiliary array.");
        // Example if an array existed: return _allowedInteractionTypes;
    }

     /**
     * @dev Retrieves the indices of memory entries delegated by an owner to a specific delegatee.
     * WARNING: Can be gas-intensive if the list of delegated indices is large.
     * @param _owner The address of the soul owner.
     * @param _delegatee The address whose delegated access list is requested.
     * @return uint256[] An array of memory indices that the delegatee has access to.
     */
    function getDelegatedMemoryAccess(address _owner, address _delegatee)
         public view soulExists(_owner) returns (uint256[] memory)
    {
         // Direct return of dynamic array - can be inefficient for large arrays
         return delegatedMemoryIndicesList[_owner][_delegatee];
    }

    // Fallback and Receive functions are not strictly needed for this concept but could be added
    // if the contract should receive plain ETH transfers (though the concept doesn't involve value).
    // receive() external payable {}
    // fallback() external payable {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Soulbound Identity (Non-Transferable):** Like SBTs, souls are bound to an address (`hasSoul` mapping and lack of transfer functions).
2.  **Dynamic & Evolving State:** Souls are not static data points.
    *   `attributes` and `emotionalResonance` are designed to change over time and based on interactions (`updateAttribute`, `updateEmotionalResonance`, `_applyDecay`).
    *   `memories` and `manualInteractions` grow over time.
    *   `connections` form a simple on-chain social graph.
    *   `soulPhase` is calculated based on age, representing maturity (`getSoulPhase`).
3.  **Time-Based Evolution (`evolveSoul`, `_applyDecay`):** Attributes can decay over time, requiring active maintenance or interaction to counteract decay. The phase also changes based on elapsed time since creation. This introduces a novel time dependency beyond simple timestamps.
4.  **Configurable Dynamics:** The owner can configure attribute decay rates (`setAttributeConfig`) and phase thresholds (`setSoulPhaseThresholds`), allowing the "rules" of soul evolution to be adjusted.
5.  **Memory System (`addMemory`, `getMemories`, `removeMemory`):** Storing structured data representing events or experiences ties the digital identity to a history of actions or inputs.
6.  **Connection Graph (`establishConnection`, `getConnections`, `removeConnection`):** Building direct, on-chain links between souls creates a rudimentary social or relational layer.
7.  **Delegated Access (`delegateMemoryAccess`, `revokeMemoryAccess`, `canAccessMemory`):** Allows granular sharing of specific pieces of soul data (memories) with other addresses, introducing a form of decentralized access control beyond simple ownership. This is an advanced pattern for structured data within a contract.
8.  **Interaction Logging (`logManualInteraction`, `logSystemInteraction`):** Tracks different types of on-chain activity, creating a historical footprint within the soul data.
9.  **Composite Scoring (`calculateSoulScore`):** Aggregates various soul attributes and history elements into a single quantifiable measure, potentially usable for reputation, eligibility, or other on-chain mechanics.
10. **Explicit Data Structuring:** Using structs (`Soul`, `MemoryEntry`, `AttributeConfig`) and mappings to organize complex, nested data associated with each address.
11. **Internal Helpers (`_applyDecay`, `_calculateSoulPhase`, `_getValueOrZero`, `logSystemInteraction`):** Using internal functions to encapsulate logic and improve code organization and safety (e.g., controlling how system interactions are logged).
12. **Gas Considerations (Not just code, but implied):** The design implicitly grapples with common Solidity challenges like managing dynamic arrays (memory/connections - mentioning potential gas costs for large arrays) and the inability to easily iterate mapping keys on-chain (necessitating specific getter functions or auxiliary arrays for configurable lists).

This contract goes beyond simply minting an NFT or storing a few static traits. It represents a stateful, dynamic digital entity that evolves based on both passive time passage and active interactions, with elements of social connection and granular data access control. It avoids directly copying standard implementations like ERC721 or Ownable by implementing core logic manually, thus adhering to the "don't duplicate open source" spirit for the *concept* and its *implementation details*.