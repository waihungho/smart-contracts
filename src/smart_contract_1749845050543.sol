Okay, here is a Solidity smart contract for an `AdvancedCyberneticAvatar`. This concept represents a dynamic, stateful digital entity that evolves, has attributes, reputation (alignment), can equip components, perform simulated actions, and changes over time based on interactions and passive decay/regeneration.

It incorporates:
*   **Dynamic State:** Attributes, energy, status, and alignment change.
*   **Time-Based Mechanics:** Attributes decay and energy regenerates based on block timestamps.
*   **Simulated Actions:** Functions represent actions that consume resources and potentially alter state.
*   **Composability:** Avatars can equip "components" (represented internally) that boost stats.
*   **Reputation System:** An `Alignment` enum tracks a simple good/evil/neutral spectrum, influenceable by actions or operators.
*   **History Tracking:** Records significant events in the avatar's life.
*   **Operator Pattern:** A role distinct from the owner for specific management tasks.
*   **Calculated Properties:** Effective attributes are calculated based on base stats and equipped components.

It avoids directly implementing standard interfaces like ERC-721/ERC-1155, focusing purely on the state and logic of the *entity* itself, which could potentially be *owned* via an external token contract or used within a game world interacting with this contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AdvancedCyberneticAvatar
 * @dev A smart contract representing dynamic, evolving digital avatars.
 * Each avatar is a stateful entity with attributes, alignment, components, history, and energy.
 * State changes occur through time passage simulation, actions, and operator interventions.
 */

// --- OUTLINE ---
// 1. Data Structures (Structs, Enums)
// 2. Events
// 3. State Variables
// 4. Modifiers
// 5. Core Logic Functions (Minting, Burning, State Updates)
// 6. Attribute & Energy Management
// 7. Alignment Management
// 8. Component Management
// 9. Action Simulation
// 10. History
// 11. Ownership & Access Control
// 12. Admin & Configuration
// 13. View Functions

// --- FUNCTION SUMMARY ---
// Core Logic:
// 1.  constructor()                     : Initializes the contract owner and base parameters.
// 2.  mint(address initialOwner)        : Creates a new avatar with base stats and assigns ownership.
// 3.  burn(uint256 avatarId)            : Destroys an avatar (callable by owner/operator).
// 4.  simulateTimePassage(uint256 avatarId) : Simulates the passage of time, applying decay/regeneration effects.

// Attribute & Energy Management:
// 5.  boostAttribute(uint256 avatarId, AttributeType attribute, uint256 amount): Increases a specific attribute, potentially costing energy.
// 6.  applyAttributeDecay(uint256 avatarId, uint256 secondsPassed) : Internal helper to apply decay.
// 7.  regenerateEnergy(uint256 avatarId, uint256 secondsPassed)    : Internal helper to regenerate energy.
// 8.  spendEnergy(uint256 avatarId, uint256 amount)                 : Internal helper to consume energy.

// Alignment Management:
// 9.  changeAlignment(uint256 avatarId, Alignment newAlignment) : Sets the avatar's alignment (operator-only).
// 10. shiftAlignment(uint256 avatarId, int256 shiftAmount)      : Shifts alignment towards a specific direction based on a value (internal/action driven).

// Component Management:
// 11. addComponent(uint256 avatarId, uint256 componentId, ComponentType componentType, mapping(uint8 => uint256) memory attributeBoosts) : Attaches a component providing attribute boosts.
// 12. removeComponent(uint256 avatarId, uint256 componentId)      : Detaches a component.

// Action Simulation:
// 13. performComplexAction(uint256 avatarId, ActionType action)   : Simulates a complex action affecting attributes, energy, alignment, and history.
// 14. rest(uint256 avatarId)              : Initiates a resting state, primarily for energy regeneration.
// 15. updateAvatarStatus(uint256 avatarId, AvatarStatus newStatus) : Sets the avatar's status (operator/self-initiated).

// History:
// 16. addHistoryEntry(uint256 avatarId, ActionType action, string memory details, mapping(uint8 => int256) memory attributeChanges) : Internal helper to add a history entry.
// 17. getHistory(uint256 avatarId)        : Retrieves the recent history entries for an avatar.
// 18. getHistoryCount(uint256 avatarId)   : Gets the total number of history entries.
// 19. clearHistory(uint256 avatarId)      : Clears the history of an avatar (operator/owner).

// Ownership & Access Control:
// 20. transferOwnership(uint256 avatarId, address newOwner) : Transfers the ownership of a specific avatar entity.
// 21. addOperator(address operator)       : Grants operator role (contract owner only).
// 22. removeOperator(address operator)    : Revokes operator role (contract owner only).
// 23. isOperator(address account)         : Checks if an address is an operator.

// Admin & Configuration:
// 24. setBaseAttributeDecayRate(uint256 rate) : Sets the global attribute decay rate (admin only).
// 25. setEnergyRegenRate(uint256 rate)    : Sets the global energy regeneration rate (admin only).
// 26. setMaxEnergy(uint256 maxEnergyValue) : Sets the maximum energy capacity (admin only).
// 27. setHistoryLimit(uint256 limit)      : Sets the maximum number of history entries stored (admin only).

// View Functions:
// 28. getAvatarSummary(uint256 avatarId)  : Gets a high-level summary of an avatar's state.
// 29. getTotalSupply()                    : Gets the total number of minted avatars.
// 30. getAvatarOwner(uint256 avatarId)    : Gets the owner of a specific avatar.
// 31. getEffectiveAttributes(uint256 avatarId) : Calculates attributes including component boosts.
// 32. getRawAttributes(uint256 avatarId)  : Gets the base attributes before boosts.
// 33. getAlignment(uint256 avatarId)      : Gets the avatar's current alignment.
// 34. getComponents(uint256 avatarId)     : Gets the list of components attached to an avatar.
// 35. getCurrentEnergy(uint256 avatarId)  : Gets the avatar's current energy.
// 36. getAvatarStatus(uint256 avatarId)   : Gets the avatar's current status.
// 37. getLastInteractionTime(uint256 avatarId) : Gets the timestamp of the last interaction/simulation.
// 38. getAttributeDecayRate()             : Gets the current attribute decay rate.
// 39. getEnergyRegenRate()              : Gets the current energy regeneration rate.
// 40. getMaxEnergy()                      : Gets the maximum energy capacity.
// 41. getHistoryLimit()                   : Gets the history storage limit.


contract AdvancedCyberneticAvatar {

    // --- 1. Data Structures ---

    enum AttributeType { Strength, Intelligence, Agility, Stamina, Charisma }
    enum ComponentType { Weapon, Armor, Utility, augment } // Example component types
    enum AvatarStatus { Active, Resting, Damaged, Idle }
    enum Alignment { LawfulGood, NeutralGood, ChaoticGood, LawfulNeutral, TrueNeutral, ChaoticNeutral, LawfulEvil, NeutralEvil, ChaoticEvil }
    enum ActionType { Explore, Train, Craft, Socialize, Combat, Rest, System } // System actions are internal triggers

    struct Attributes {
        uint256 strength;
        uint256 intelligence;
        uint256 agility;
        uint256 stamina;
        uint256 charisma;
    }

    struct Component {
        uint256 componentId; // Unique ID for the component instance (e.g., could be an external NFT ID)
        ComponentType componentType;
        mapping(uint8 => uint256) attributeBoosts; // mapping enum index to boost value
        bool isActive; // Could allow toggling components
    }

    struct HistoryEntry {
        uint64 timestamp;
        ActionType actionType;
        string details;
        // Mapping attribute index to change amount (positive or negative)
        mapping(uint8 => int256) attributeChanges;
    }

    struct Avatar {
        uint256 id;
        address owner;
        Attributes baseAttributes; // Attributes before boosts
        Alignment alignment;
        AvatarStatus status;
        uint64 creationTime;
        uint64 lastInteractionTime;
        uint256 currentEnergy;
        uint256 maxEnergy; // Can be per-avatar or global, let's make it settable globally
        Component[] components; // Array of attached components
        HistoryEntry[] history; // Dynamic array to store history (can grow)
    }

    // --- 2. Events ---

    event AvatarMinted(uint256 indexed avatarId, address indexed owner, uint64 timestamp);
    event AvatarBurned(uint256 indexed avatarId, address indexed owner, uint64 timestamp);
    event AttributesBoosted(uint256 indexed avatarId, AttributeType attribute, uint256 amount, uint64 timestamp);
    event AttributesDecayed(uint256 indexed avatarId, uint64 timestamp, mapping(uint8 => uint256) decayAmounts);
    event EnergyRegenerated(uint256 indexed avatarId, uint256 amount, uint256 newEnergy, uint64 timestamp);
    event EnergySpent(uint256 indexed avatarId, uint256 amount, uint256 newEnergy, uint64 timestamp);
    event AlignmentChanged(uint256 indexed avatarId, Alignment oldAlignment, Alignment newAlignment, uint64 timestamp);
    event ComponentAdded(uint255 indexed avatarId, uint256 indexed componentId, ComponentType componentType, uint64 timestamp);
    event ComponentRemoved(uint256 indexed avatarId, uint256 indexed componentId, uint64 timestamp);
    event ActionPerformed(uint256 indexed avatarId, ActionType action, string details, uint64 timestamp);
    event StatusChanged(uint256 indexed avatarId, AvatarStatus oldStatus, AvatarStatus newStatus, uint64 timestamp);
    event OwnershipTransferred(uint256 indexed avatarId, address indexed oldOwner, address indexed newOwner, uint64 timestamp);
    event OperatorAdded(address indexed operator, uint64 timestamp);
    event OperatorRemoved(address indexed operator, uint64 timestamp);
    event AdminParamUpdated(string paramName, uint256 newValue, uint64 timestamp);
    event HistoryEntryAdded(uint256 indexed avatarId, uint64 entryTimestamp, ActionType actionType, string details);
    event HistoryCleared(uint256 indexed avatarId, uint64 timestamp);


    // --- 3. State Variables ---

    mapping(uint256 => Avatar) public avatars;
    mapping(uint256 => bool) public avatarExists;
    uint256 private _avatarCount; // Total number of avatars ever minted

    address public owner; // Contract owner
    mapping(address => bool) public operators; // Addresses with operator privileges

    // Configuration parameters (admin settable)
    uint256 public baseAttributeDecayRatePerSecond = 0; // How much each attribute decays per second globally
    uint256 public energyRegenRatePerSecond = 1; // How much energy regenerates per second globally
    uint256 public maxEnergy = 100; // Max energy capacity globally
    uint256 public historyLimit = 10; // Maximum number of history entries to store per avatar

    // --- 4. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "ACA: Caller is not the contract owner");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner, "ACA: Caller is not an authorized operator");
        _;
    }

    modifier avatarExists(uint256 _avatarId) {
        require(avatarExists[_avatarId], "ACA: Avatar does not exist");
        _;
    }

    modifier isAvatarOwnerOrOperator(uint256 _avatarId) {
        require(avatars[_avatarId].owner == msg.sender || operators[msg.sender] || msg.sender == owner, "ACA: Caller is not avatar owner or operator");
        _;
    }

    modifier isAvatarOwner(uint256 _avatarId) {
        require(avatars[_avatarId].owner == msg.sender, "ACA: Caller is not avatar owner");
        _;
    }


    // --- 5. Core Logic Functions ---

    constructor() {
        owner = msg.sender;
        operators[msg.sender] = true; // Contract owner is also an operator by default
        emit OperatorAdded(msg.sender, uint64(block.timestamp));
    }

    /// @notice Creates a new avatar and assigns it to an initial owner.
    /// @param initialOwner The address that will initially own the new avatar.
    /// @return avatarId The ID of the newly minted avatar.
    function mint(address initialOwner) public onlyOwner returns (uint256 avatarId) {
        _avatarCount++;
        avatarId = _avatarCount;

        avatars[avatarId] = Avatar({
            id: avatarId,
            owner: initialOwner,
            baseAttributes: Attributes({ strength: 10, intelligence: 10, agility: 10, stamina: 10, charisma: 10 }),
            alignment: Alignment.TrueNeutral,
            status: AvatarStatus.Idle,
            creationTime: uint64(block.timestamp),
            lastInteractionTime: uint64(block.timestamp),
            currentEnergy: maxEnergy, // Start with full energy
            maxEnergy: maxEnergy, // Copy global max energy
            components: new Component[](0),
            history: new HistoryEntry[](0)
        });
        avatarExists[avatarId] = true;

        // Add initial history entry
        addHistoryEntry(avatarId, ActionType.System, "Avatar Minted", new mapping(uint8 => int256)(0));

        emit AvatarMinted(avatarId, initialOwner, uint64(block.timestamp));
    }

    /// @notice Destroys an avatar. Only callable by the avatar owner or an operator.
    /// @param avatarId The ID of the avatar to burn.
    function burn(uint256 avatarId) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        address avatarOwner = avatars[avatarId].owner;

        // Clear storage (important for gas costs and security)
        delete avatars[avatarId];
        avatarExists[avatarId] = false;

        emit AvatarBurned(avatarId, avatarOwner, uint64(block.timestamp));
    }

    /// @notice Simulates the passage of time for an avatar, applying decay and regeneration.
    /// Can be triggered by anyone, but effects only apply based on time since last interaction.
    /// @param avatarId The ID of the avatar to simulate time for.
    function simulateTimePassage(uint256 avatarId) public avatarExists(avatarId) {
        Avatar storage avatar = avatars[avatarId];
        uint64 currentTime = uint64(block.timestamp);
        uint256 secondsPassed = currentTime - avatar.lastInteractionTime;

        if (secondsPassed > 0) {
            // Apply decay to attributes
            applyAttributeDecay(avatarId, secondsPassed);

            // Regenerate energy
            regenerateEnergy(avatarId, secondsPassed);

            // Update last interaction time
            avatar.lastInteractionTime = currentTime;

             // Log the system action
            addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Simulated time passage (", secondsPassed, "s)")), new mapping(uint8 => int256)(0));
        }
    }

    // --- 6. Attribute & Energy Management ---

    /// @notice Boosts a specific attribute of an avatar. May consume energy or other resources (not implemented here, simplify to just a boost).
    /// Requires avatar owner or operator.
    /// @param avatarId The ID of the avatar.
    /// @param attribute The type of attribute to boost.
    /// @param amount The amount to increase the attribute by.
    function boostAttribute(uint256 avatarId, AttributeType attribute, uint256 amount) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        Avatar storage avatar = avatars[avatarId];

        // Example cost: require energy
        uint256 energyCost = amount * 2; // Arbitrary cost
        require(avatar.currentEnergy >= energyCost, "ACA: Not enough energy to boost attribute");
        spendEnergy(avatarId, energyCost); // Use the internal helper

        if (attribute == AttributeType.Strength) avatar.baseAttributes.strength += amount;
        else if (attribute == AttributeType.Intelligence) avatar.baseAttributes.intelligence += amount;
        else if (attribute == AttributeType.Agility) avatar.baseAttributes.agility += amount;
        else if (attribute == AttributeType.Stamina) avatar.baseAttributes.stamina += amount;
        else if (attribute == AttributeType.Charisma) avatar.baseAttributes.charisma += amount;

        // Log the attribute change in history
        mapping(uint8 => int256) memory changes = new mapping(uint8 => int256)(0);
        changes[uint8(attribute)] = int256(amount);
        addHistoryEntry(avatarId, ActionType.Train, string(abi.encodePacked("Boosted ", uint8(attribute), " by ", amount)), changes);

        emit AttributesBoosted(avatarId, attribute, amount, uint64(block.timestamp));
    }

    /// @dev Internal helper to apply attribute decay based on time.
    /// @param avatarId The ID of the avatar.
    /// @param secondsPassed The number of seconds passed since last interaction.
    function applyAttributeDecay(uint256 avatarId, uint256 secondsPassed) internal avatarExists(avatarId) {
        if (baseAttributeDecayRatePerSecond == 0 || secondsPassed == 0) return;

        Avatar storage avatar = avatars[avatarId];
        uint256 decayAmount = baseAttributeDecayRatePerSecond * secondsPassed;

        // Decay attributes, ensuring they don't go below a minimum (e.g., 1)
        mapping(uint8 => uint256) memory decayed = new mapping(uint8 => uint256)(0);
        if (avatar.baseAttributes.strength > decayAmount) { avatar.baseAttributes.strength -= decayAmount; decayed[uint8(AttributeType.Strength)] = decayAmount; } else { avatar.baseAttributes.strength = 1; decayed[uint8(AttributeType.Strength)] = avatar.baseAttributes.strength - 1; }
        if (avatar.baseAttributes.intelligence > decayAmount) { avatar.baseAttributes.intelligence -= decayAmount; decayed[uint8(AttributeType.Intelligence)] = decayAmount; } else { avatar.baseAttributes.intelligence = 1; decayed[uint8(AttributeType.Intelligence)] = avatar.baseAttributes.intelligence - 1; }
        if (avatar.baseAttributes.agility > decayAmount) { avatar.baseAttributes.agility -= decayAmount; decayed[uint8(AttributeType.Agility)] = decayAmount; } else { avatar.baseAttributes.agility = 1; decayed[uint8(AttributeType.Agility)] = avatar.baseAttributes.agility - 1; }
        if (avatar.baseAttributes.stamina > decayAmount) { avatar.baseAttributes.stamina -= decayAmount; decayed[uint8(AttributeType.Stamina)] = decayAmount; } else { avatar.baseAttributes.stamina = 1; decayed[uint8(AttributeType.Stamina)] = avatar.baseAttributes.stamina - 1; }
        if (avatar.baseAttributes.charisma > decayAmount) { avatar.baseAttributes.charisma -= decayAmount; decayed[uint8(AttributeType.Charisma)] = decayAmount; } else { avatar.baseAttributes.charisma = 1; decayed[uint8(AttributeType.Charisma)] = avatar.baseAttributes.charisma - 1; }

         // Log decay in history
        mapping(uint8 => int256) memory changes = new mapping(uint8 => int256)(0);
        changes[uint8(AttributeType.Strength)] = -int256(decayed[uint8(AttributeType.Strength)]);
        changes[uint8(AttributeType.Intelligence)] = -int256(decayed[uint8(AttributeType.Intelligence)]);
        changes[uint8(AttributeType.Agility)] = -int256(decayed[uint8(AttributeType.Agility)]);
        changes[uint8(AttributeType.Stamina)] = -int256(decayed[uint8(AttributeType.Stamina)]);
        changes[uint8(AttributeType.Charisma)] = -int256(decayed[uint8(AttributeType.Charisma)]);
        addHistoryEntry(avatarId, ActionType.System, "Attribute Decay", changes);


        emit AttributesDecayed(avatarId, uint64(block.timestamp), decayed);
    }

    /// @dev Internal helper to regenerate energy based on time and status.
    /// @param avatarId The ID of the avatar.
    /// @param secondsPassed The number of seconds passed since last interaction.
    function regenerateEnergy(uint256 avatarId, uint256 secondsPassed) internal avatarExists(avatarId) {
        if (energyRegenRatePerSecond == 0 || secondsPassed == 0) return;

        Avatar storage avatar = avatars[avatarId];
        uint256 regenAmount = energyRegenRatePerSecond * secondsPassed;

        // Maybe regen faster when Resting
        if (avatar.status == AvatarStatus.Resting) {
             regenAmount = regenAmount * 2; // Example: double regen when resting
        }

        uint256 oldEnergy = avatar.currentEnergy;
        avatar.currentEnergy = Math.min(avatar.currentEnergy + regenAmount, avatar.maxEnergy);

        if (avatar.currentEnergy > oldEnergy) {
             emit EnergyRegenerated(avatarId, avatar.currentEnergy - oldEnergy, avatar.currentEnergy, uint64(block.timestamp));
        }
    }

     /// @dev Internal helper to spend energy.
     /// @param avatarId The ID of the avatar.
     /// @param amount The amount of energy to spend.
    function spendEnergy(uint256 avatarId, uint256 amount) internal avatarExists(avatarId) {
         Avatar storage avatar = avatars[avatarId];
         require(avatar.currentEnergy >= amount, "ACA: Insufficient energy");
         uint256 oldEnergy = avatar.currentEnergy;
         avatar.currentEnergy = avatar.currentEnergy - amount;
         emit EnergySpent(avatarId, amount, avatar.currentEnergy, uint64(block.timestamp));
     }


    // --- 7. Alignment Management ---

    /// @notice Sets the alignment of an avatar. This is an operator-only function, potentially for GM tools.
    /// @param avatarId The ID of the avatar.
    /// @param newAlignment The new alignment to set.
    function changeAlignment(uint256 avatarId, Alignment newAlignment) public avatarExists(avatarId) onlyOperator {
        Avatar storage avatar = avatars[avatarId];
        Alignment oldAlignment = avatar.alignment;
        avatar.alignment = newAlignment;

        // Log the change
        addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Alignment changed from ", uint8(oldAlignment), " to ", uint8(newAlignment))), new mapping(uint8 => int256)(0));

        emit AlignmentChanged(avatarId, oldAlignment, newAlignment, uint64(block.timestamp));
    }

    /// @dev Internal helper to shift alignment based on a value. Positive shifts towards Lawful/Good, negative towards Chaotic/Evil.
    /// This provides a more nuanced way to influence alignment via actions.
    /// @param avatarId The ID of the avatar.
    /// @param shiftAmount The amount to shift the alignment. Positive for good/lawful shift, negative for evil/chaotic shift.
    function shiftAlignment(uint256 avatarId, int256 shiftAmount) internal avatarExists(avatarId) {
        // Simple mapping: LawfulGood=0, ... ChaoticEvil=8
        // Shift towards 0 for lawful/good, towards 8 for chaotic/evil
        // This is a very simple implementation; a real system would be more complex.
        Avatar storage avatar = avatars[avatarId];
        int256 currentAlignmentIndex = int256(uint8(avatar.alignment));
        int256 newAlignmentIndex = currentAlignmentIndex - shiftAmount; // Positive shiftAmount means decrement index (towards LawfulGood=0)

        // Clamp the new index between 0 and 8
        newAlignmentIndex = Math.max(0, newAlignmentIndex);
        newAlignmentIndex = Math.min(8, newAlignmentIndex);

        Alignment oldAlignment = avatar.alignment;
        avatar.alignment = Alignment(uint8(newAlignmentIndex));

        if (avatar.alignment != oldAlignment) {
            addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Alignment shifted by ", shiftAmount)), new mapping(uint8 => int256)(0));
            emit AlignmentChanged(avatarId, oldAlignment, avatar.alignment, uint64(block.timestamp));
        }
    }


    // --- 8. Component Management ---

    /// @notice Adds a component to an avatar. Requires avatar owner or operator.
    /// Note: The `componentId` here is an internal representation. In a real system, this might be an external NFT token ID and contract address.
    /// @param avatarId The ID of the avatar.
    /// @param componentId The unique identifier for this component instance.
    /// @param componentType The type of component being added.
    /// @param attributeBoosts A mapping specifying attribute boosts provided by this component (enum index => amount).
    function addComponent(uint256 avatarId, uint256 componentId, ComponentType componentType, mapping(uint8 => uint256) memory attributeBoosts) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        Avatar storage avatar = avatars[avatarId];

        // Prevent adding duplicate components by componentId (simple check)
        for (uint i = 0; i < avatar.components.length; i++) {
            require(avatar.components[i].componentId != componentId, "ACA: Component with this ID already attached");
        }

        Component memory newComponent;
        newComponent.componentId = componentId;
        newComponent.componentType = componentType;
        newComponent.isActive = true; // Components are active by default

        // Copy attribute boosts from memory to storage
        for (uint8 i = 0; i < 5; i++) { // Iterate through AttributeType enum indices
            newComponent.attributeBoosts[i] = attributeBoosts[i];
        }

        avatar.components.push(newComponent);

        // Log the change
        addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Component added (ID: ", componentId, ", Type: ", uint8(componentType), ")")), new mapping(uint8 => int256)(0));

        emit ComponentAdded(avatarId, componentId, componentType, uint64(block.timestamp));
    }

    /// @notice Removes a component from an avatar by its component ID. Requires avatar owner or operator.
    /// @param avatarId The ID of the avatar.
    /// @param componentId The unique identifier of the component to remove.
    function removeComponent(uint256 avatarId, uint256 componentId) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        Avatar storage avatar = avatars[avatarId];
        bool found = false;
        uint256 indexToRemove = avatar.components.length;

        for (uint i = 0; i < avatar.components.length; i++) {
            if (avatar.components[i].componentId == componentId) {
                indexToRemove = i;
                found = true;
                break;
            }
        }

        require(found, "ACA: Component not found on avatar");

        // Efficient removal from dynamic array: swap with last element and pop
        if (indexToRemove != avatar.components.length - 1) {
            avatar.components[indexToRemove] = avatar.components[avatar.components.length - 1];
        }
        avatar.components.pop();

        // Log the change
        addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Component removed (ID: ", componentId, ")")), new mapping(uint8 => int256)(0));

        emit ComponentRemoved(avatarId, componentId, uint64(block.timestamp));
    }


    // --- 9. Action Simulation ---

    /// @notice Simulates a complex action performed by the avatar.
    /// This is a core function where game/application logic would live.
    /// It triggers time simulation, consumes energy, potentially changes attributes, alignment, and adds history.
    /// Requires avatar owner or operator.
    /// @param avatarId The ID of the avatar performing the action.
    /// @param action The type of action being performed.
    function performComplexAction(uint256 avatarId, ActionType action) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        Avatar storage avatar = avatars[avatarId];

        // 1. Simulate time passage first to update state based on idle time
        simulateTimePassage(avatarId);

        // 2. Check prerequisites for the action (e.g., energy cost, status)
        uint256 energyCost = 10; // Example base cost

        if (action == ActionType.Explore) energyCost = 15;
        else if (action == ActionType.Train) energyCost = 12;
        else if (action == ActionType.Craft) energyCost = 8;
        else if (action == ActionType.Socialize) energyCost = 5;
        else if (action == ActionType.Combat) energyCost = 20;
        // Rest action is handled separately or via updateStatus

        require(avatar.currentEnergy >= energyCost, "ACA: Not enough energy for this action");
        spendEnergy(avatarId, energyCost);

        // 3. Perform action effects (example simplified logic)
        string memory actionDetails = "";
        mapping(uint8 => int256) memory attributeChanges = new mapping(uint8 => int256)(0);
        int256 alignmentShift = 0; // Positive shifts towards Lawful/Good

        if (action == ActionType.Explore) {
            // Explore might increase agility, intelligence, and potentially shift alignment
            uint256 agilityGain = Math.max(1, getEffectiveAttributes(avatarId).agility / 50); // Gain based on effective agility
            avatar.baseAttributes.agility += agilityGain;
            attributeChanges[uint8(AttributeType.Agility)] = int256(agilityGain);
            actionDetails = string(abi.encodePacked("Explored surroundings. Gained ", agilityGain, " Agility."));
            alignmentShift = -1; // Exploring might lean towards chaotic
        } else if (action == ActionType.Train) {
            // Train might increase strength or stamina
             uint256 strengthGain = Math.max(1, getEffectiveAttributes(avatarId).strength / 50);
             uint256 staminaGain = Math.max(1, getEffectiveAttributes(avatarId).stamina / 60);
             avatar.baseAttributes.strength += strengthGain;
             avatar.baseAttributes.stamina += staminaGain;
             attributeChanges[uint8(AttributeType.Strength)] = int256(strengthGain);
             attributeChanges[uint8(AttributeType.Stamina)] = int256(staminaGain);
             actionDetails = string(abi.encodePacked("Trained skills. Gained ", strengthGain, " Strength, ", staminaGain, " Stamina."));
             alignmentShift = 1; // Training might lean towards lawful
        } // ... add more actions

        // 4. Apply alignment shift
        shiftAlignment(avatarId, alignmentShift);

        // 5. Log the action
        addHistoryEntry(avatarId, action, actionDetails, attributeChanges);

        // 6. Emit event
        emit ActionPerformed(avatarId, action, actionDetails, uint64(block.timestamp));

        // 7. Update last interaction time again after the action
        avatar.lastInteractionTime = uint64(block.timestamp);
    }

     /// @notice Sets the avatar's status to Resting.
     /// This doesn't require energy but prevents other actions and boosts energy regen.
     /// Requires avatar owner or operator.
     /// @param avatarId The ID of the avatar.
     function rest(uint256 avatarId) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
         updateAvatarStatus(avatarId, AvatarStatus.Resting);
     }

    /// @notice Updates the avatar's status. Requires avatar owner or operator.
    /// @param avatarId The ID of the avatar.
    /// @param newStatus The new status to set.
    function updateAvatarStatus(uint256 avatarId, AvatarStatus newStatus) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        Avatar storage avatar = avatars[avatarId];
        AvatarStatus oldStatus = avatar.status;
        require(oldStatus != newStatus, "ACA: Avatar already in this status");

        avatar.status = newStatus;

        // Log the change
        addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Status changed from ", uint8(oldStatus), " to ", uint8(newStatus))), new mapping(uint8 => int256)(0));

        emit StatusChanged(avatarId, oldStatus, newStatus, uint64(block.timestamp));

        // Update last interaction time
        avatar.lastInteractionTime = uint64(block.timestamp);
    }


    // --- 10. History ---

    /// @dev Internal helper function to add an entry to the avatar's history.
    /// Handles the history limit by removing the oldest entry if the limit is reached.
    /// @param avatarId The ID of the avatar.
    /// @param action The type of action.
    /// @param details String details of the action.
    /// @param attributeChanges Mapping of attribute indices to their change amounts (can be negative).
    function addHistoryEntry(uint256 avatarId, ActionType action, string memory details, mapping(uint8 => int256) memory attributeChanges) internal avatarExists(avatarId) {
        Avatar storage avatar = avatars[avatarId];

        // If history limit is reached, remove the oldest entry
        if (avatar.history.length >= historyLimit && historyLimit > 0) {
            // Shift all elements left
            for (uint i = 0; i < avatar.history.length - 1; i++) {
                avatar.history[i] = avatar.history[i+1];
            }
            // Remove the last element (which is now a duplicate of the second newest)
            avatar.history.pop();
        }

        // Add the new entry
        HistoryEntry memory newEntry;
        newEntry.timestamp = uint64(block.timestamp);
        newEntry.actionType = action;
        newEntry.details = details;

        // Copy attribute changes from memory to storage
        for (uint8 i = 0; i < 5; i++) { // Iterate through AttributeType enum indices
             // Only copy if there was a non-zero change
             if (attributeChanges[i] != 0) {
                newEntry.attributeChanges[i] = attributeChanges[i];
             }
        }

        avatar.history.push(newEntry);

         emit HistoryEntryAdded(avatarId, newEntry.timestamp, action, details);
    }

     /// @notice Retrieves the recent history entries for an avatar, limited by the historyLimit.
     /// @param avatarId The ID of the avatar.
     /// @return An array of HistoryEntry structs.
    function getHistory(uint256 avatarId) public view avatarExists(avatarId) returns (HistoryEntry[] memory) {
         Avatar storage avatar = avatars[avatarId];
         // Return the entire history array stored (which is capped by historyLimit)
         return avatar.history;
     }

     /// @notice Gets the total number of history entries stored for an avatar.
     /// @param avatarId The ID of the avatar.
     /// @return The number of history entries.
    function getHistoryCount(uint256 avatarId) public view avatarExists(avatarId) returns (uint256) {
        return avatars[avatarId].history.length;
    }

    /// @notice Clears the history of an avatar. Requires avatar owner or operator.
    /// @param avatarId The ID of the avatar.
    function clearHistory(uint256 avatarId) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        delete avatars[avatarId].history; // Clears the dynamic array

        // Log the clear action itself in the newly cleared history (optional, depends on desired behavior)
        // For simplicity, just emit an event that it was cleared
        emit HistoryCleared(avatarId, uint64(block.timestamp));
    }


    // --- 11. Ownership & Access Control ---

    /// @notice Transfers the ownership of a specific avatar entity to a new address.
    /// Only the current owner of the avatar or an operator can call this.
    /// Note: This is transferring the *entity's* internal ownership state, not necessarily an ERC-721 token.
    /// @param avatarId The ID of the avatar.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(uint256 avatarId, address newOwner) public avatarExists(avatarId) isAvatarOwnerOrOperator(avatarId) {
        require(newOwner != address(0), "ACA: New owner is the zero address");
        Avatar storage avatar = avatars[avatarId];
        address oldOwner = avatar.owner;
        require(oldOwner != newOwner, "ACA: Avatar already owned by this address");

        avatar.owner = newOwner;

        // Log the transfer
        addHistoryEntry(avatarId, ActionType.System, string(abi.encodePacked("Ownership transferred to ", newOwner)), new mapping(uint8 => int256)(0));

        emit OwnershipTransferred(avatarId, oldOwner, newOwner, uint64(block.timestamp));
    }

    /// @notice Grants the operator role to an address. Only callable by the contract owner.
    /// Operators can perform certain administrative actions on any avatar.
    /// @param operator The address to grant the role to.
    function addOperator(address operator) public onlyOwner {
        require(operator != address(0), "ACA: Cannot add zero address as operator");
        require(!operators[operator], "ACA: Address is already an operator");
        operators[operator] = true;

        emit OperatorAdded(operator, uint64(block.timestamp));
    }

    /// @notice Revokes the operator role from an address. Only callable by the contract owner.
    /// @param operator The address to revoke the role from.
    function removeOperator(address operator) public onlyOwner {
         require(operator != address(0), "ACA: Cannot remove zero address");
         require(operators[operator], "ACA: Address is not an operator");
         require(operator != owner, "ACA: Cannot remove contract owner from operators"); // Contract owner is always an operator

        operators[operator] = false;

        emit OperatorRemoved(operator, uint64(block.timestamp));
    }

    /// @notice Checks if an address has the operator role.
    /// @param account The address to check.
    /// @return True if the address is an operator or the contract owner, false otherwise.
    function isOperator(address account) public view returns (bool) {
        return operators[account] || account == owner;
    }


    // --- 12. Admin & Configuration ---

    /// @notice Sets the global rate at which base attributes decay per second. Only callable by the contract owner.
    /// @param rate The new decay rate per second.
    function setBaseAttributeDecayRate(uint256 rate) public onlyOwner {
        baseAttributeDecayRatePerSecond = rate;
        emit AdminParamUpdated("baseAttributeDecayRatePerSecond", rate, uint64(block.timestamp));
    }

    /// @notice Sets the global rate at which energy regenerates per second. Only callable by the contract owner.
    /// @param rate The new regeneration rate per second.
    function setEnergyRegenRate(uint256 rate) public onlyOwner {
        energyRegenRatePerSecond = rate;
        emit AdminParamUpdated("energyRegenRatePerSecond", rate, uint64(block.timestamp));
    }

    /// @notice Sets the global maximum energy capacity for all avatars. Only callable by the contract owner.
    /// Does NOT update existing avatars' `maxEnergy` or `currentEnergy`. This would require a separate migration function.
    /// @param maxEnergyValue The new maximum energy capacity.
    function setMaxEnergy(uint256 maxEnergyValue) public onlyOwner {
        maxEnergy = maxEnergyValue;
        emit AdminParamUpdated("maxEnergy", maxEnergyValue, uint64(block.timestamp));
    }

     /// @notice Sets the maximum number of history entries to store per avatar. Only callable by the contract owner.
     /// Does NOT retroactively trim history for existing avatars; trimming occurs on the *next* history entry addition.
     /// @param limit The new history storage limit. Set to 0 for no limit (use with caution).
    function setHistoryLimit(uint256 limit) public onlyOwner {
         historyLimit = limit;
         emit AdminParamUpdated("historyLimit", limit, uint64(block.timestamp));
     }


    // --- 13. View Functions ---

     /// @notice Gets a summary of key information for an avatar.
     /// @param avatarId The ID of the avatar.
     /// @return id The avatar's ID.
     /// @return owner The avatar's owner address.
     /// @return status The avatar's current status.
     /// @return alignment The avatar's current alignment.
     /// @return currentEnergy The avatar's current energy.
     /// @return maxEnergy The avatar's max energy.
     /// @return creationTime The avatar's creation timestamp.
     /// @return lastInteractionTime The avatar's last interaction timestamp.
     /// @return effectiveAttributes The avatar's attributes including component boosts.
    function getAvatarSummary(uint256 avatarId) public view avatarExists(avatarId)
        returns (
            uint256 id,
            address owner,
            AvatarStatus status,
            Alignment alignment,
            uint256 currentEnergy,
            uint256 maxEnergy,
            uint64 creationTime,
            uint64 lastInteractionTime,
            Attributes memory effectiveAttributes
        )
    {
        Avatar storage avatar = avatars[avatarId];
        return (
            avatar.id,
            avatar.owner,
            avatar.status,
            avatar.alignment,
            avatar.currentEnergy,
            avatar.maxEnergy,
            avatar.creationTime,
            avatar.lastInteractionTime,
            getEffectiveAttributes(avatarId) // Call the helper view function
        );
    }

    /// @notice Gets the total number of avatars that have been minted.
    /// @return The total supply count.
    function getTotalSupply() public view returns (uint256) {
        return _avatarCount;
    }

    /// @notice Gets the owner address for a specific avatar.
    /// @param avatarId The ID of the avatar.
    /// @return The owner's address.
    function getAvatarOwner(uint256 avatarId) public view avatarExists(avatarId) returns (address) {
        return avatars[avatarId].owner;
    }

    /// @notice Calculates and returns the effective attributes of an avatar, including base attributes and active component boosts.
    /// @param avatarId The ID of the avatar.
    /// @return attributes The calculated Attributes struct.
    function getEffectiveAttributes(uint256 avatarId) public view avatarExists(avatarId) returns (Attributes memory) {
        Avatar storage avatar = avatars[avatarId];
        Attributes memory effective = avatar.baseAttributes;

        for (uint i = 0; i < avatar.components.length; i++) {
            if (avatar.components[i].isActive) {
                 effective.strength += avatar.components[i].attributeBoosts[uint8(AttributeType.Strength)];
                 effective.intelligence += avatar.components[i].attributeBoosts[uint8(AttributeType.Intelligence)];
                 effective.agility += avatar.components[i].attributeBoosts[uint8(AttributeType.Agility)];
                 effective.stamina += avatar.components[i].attributeBoosts[uint8(AttributeType.Stamina)];
                 effective.charisma += avatar.components[i].attributeBoosts[uint8(AttributeType.Charisma)];
            }
        }
        return effective;
    }

    /// @notice Gets the base attributes of an avatar, before any component boosts.
    /// @param avatarId The ID of the avatar.
    /// @return attributes The base Attributes struct.
    function getRawAttributes(uint256 avatarId) public view avatarExists(avatarId) returns (Attributes memory) {
        return avatars[avatarId].baseAttributes;
    }

    /// @notice Gets the current alignment of an avatar.
    /// @param avatarId The ID of the avatar.
    /// @return The avatar's Alignment enum value.
    function getAlignment(uint256 avatarId) public view avatarExists(avatarId) returns (Alignment) {
        return avatars[avatarId].alignment;
    }

    /// @notice Gets the list of components currently attached to an avatar.
    /// Note: This returns a copy of the storage array.
    /// @param avatarId The ID of the avatar.
    /// @return An array of Component structs.
    function getComponents(uint256 avatarId) public view avatarExists(avatarId) returns (Component[] memory) {
        // Need to manually copy the data to a memory array because mappings in structs cannot be returned directly from storage in Solidity pre-0.6.0.
        // Even in 0.8.x, complex nested mappings/structs often require manual copying for views.
        // A more gas-efficient approach for many components might be indexed lookups, or paginated results.
        // For this example, we'll copy the array of components, but be aware of potential gas costs with many components.
        Avatar storage avatar = avatars[avatarId];
        Component[] memory componentsMemory = new Component[](avatar.components.length);
        for (uint i = 0; i < avatar.components.length; i++) {
             componentsMemory[i].componentId = avatar.components[i].componentId;
             componentsMemory[i].componentType = avatar.components[i].componentType;
             componentsMemory[i].isActive = avatar.components[i].isActive;
             // Cannot directly copy the internal mapping. A view function returning boosts for a specific component ID might be needed,
             // or restructure `Component` struct if possible.
             // For now, this view returns component IDs, Types, and active status.
             // A separate view might be needed to get boosts for a specific component ID on an avatar.
             // Let's add a simpler struct for the view return that doesn't include the mapping.
        }

         struct ComponentView {
             uint256 componentId;
             ComponentType componentType;
             bool isActive;
             // Cannot include mapping here. Boosts need a separate function call per component or a different data structure.
             // Let's skip returning boosts in this general view for simplicity.
         }

         ComponentView[] memory componentsView = new ComponentView[](avatar.components.length);
         for (uint i = 0; i < avatar.components.length; i++) {
             componentsView[i].componentId = avatar.components[i].componentId;
             componentsView[i].componentType = avatar.components[i].componentType;
             componentsView[i].isActive = avatar.components[i].isActive;
         }
        return avatar.components; // Let's revert and just return the storage array directly as allowed in recent Solidity for simple cases.
                                  // The mapping inside the struct might still cause issues depending on compiler/ABI, but let's try this first.
                                  // If ABI generation fails, the struct needs flattening for views or a dedicated function per component.
    }

    /// @notice Gets the current energy level of an avatar.
    /// @param avatarId The ID of the avatar.
    /// @return The current energy amount.
    function getCurrentEnergy(uint256 avatarId) public view avatarExists(avatarId) returns (uint256) {
        return avatars[avatarId].currentEnergy;
    }

    /// @notice Gets the current status of an avatar.
    /// @param avatarId The ID of the avatar.
    /// @return The avatar's AvatarStatus enum value.
    function getAvatarStatus(uint256 avatarId) public view avatarExists(avatarId) returns (AvatarStatus) {
        return avatars[avatarId].status;
    }

    /// @notice Gets the timestamp of the avatar's last interaction or simulation event.
    /// Used by simulateTimePassage to calculate elapsed time.
    /// @param avatarId The ID of the avatar.
    /// @return The timestamp (uint64).
    function getLastInteractionTime(uint256 avatarId) public view avatarExists(avatarId) returns (uint64) {
        return avatars[avatarId].lastInteractionTime;
    }

    /// @notice Gets the global base attribute decay rate per second.
    /// @return The decay rate.
    function getAttributeDecayRate() public view returns (uint256) {
        return baseAttributeDecayRatePerSecond;
    }

    /// @notice Gets the global energy regeneration rate per second.
    /// @return The regeneration rate.
    function getEnergyRegenRate() public view returns (uint256) {
        return energyRegenRatePerSecond;
    }

    /// @notice Gets the global maximum energy capacity.
    /// @return The max energy value.
    function getMaxEnergy() public view returns (uint256) {
        return maxEnergy;
    }

    /// @notice Gets the maximum number of history entries stored per avatar.
    /// @return The history limit.
    function getHistoryLimit() public view returns (uint256) {
        return historyLimit;
    }


    // --- Utility Library (Simple Math) ---
    // Added a simple Math library for min/max, as importing SafeMath etc. isn't strictly necessary for this example and increases complexity.
    // In production, consider using OpenZeppelin's SafeMath for arithmetic if overflows are a concern on additions (though Solidity 0.8+ checks by default).

    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
        function abs(int256 x) internal pure returns (uint256) {
            return x >= 0 ? uint256(x) : uint256(-x);
        }
    }
}
```