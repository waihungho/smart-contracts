Okay, here is a smart contract concept leveraging a metaphorical "Quantum Entanglement Registry". It simulates entanglement and collapse between on-chain entities (called "Particles"), allowing for complex state dependencies and controlled finalization.

This contract introduces:
1.  **Simulated Entanglement:** Particles can be linked such that updating the state of one *must* instantaneously update the state of the entangled partner based on predefined rules.
2.  **State Collapse:** A process to finalize the state of entangled particles, preventing further updates or entanglement.
3.  **Entanglement Types:** Different rules governing how entangled states relate (e.g., equal, sum, modulo dependency).
4.  **Delegated Collapse:** Allowing other addresses to trigger the collapse of your particles.
5.  **Scheduled & Event-Triggered Collapse:** Automating or externalizing collapse triggers.
6.  **On-chain Metadata Linking:** Storing a hash that points to off-chain information relevant to the particles or contract.

It is designed to be conceptually interesting and include a wide range of functions, aiming for complexity beyond typical ERC-20/721 or simple DeFi examples.

---

**Contract Outline & Function Summary**

*   **Contract Name:** `QuantumEntanglementRegistry`
*   **Concept:** A registry for managing abstract "Particles" that can be created, entangled with other particles, have their states updated according to entanglement rules, and eventually undergo "collapse" to finalize their states.
*   **Key Data Structures:**
    *   `Particle`: Represents an individual entity with properties like ID, owner, state (`uint256`), entanglement status, collapse status, timestamps, and specific parameters (`conditionValue`) potentially used in entanglement logic.
    *   `EntanglementLink`: Represents the connection between two particles, specifying the `EntanglementType` and a `conditionValue` for dependency calculations.
    *   `EntanglementType` (Enum): Defines the rules for state dependency between entangled particles (`EQUAL_STATE`, `SUM_DEPENDENCY`, `MODULO_DEPENDENCY`).
*   **Function Categories:**
    *   **Particle Management:** Creation, retrieval, transfer of ownership.
    *   **Entanglement Management:** Linking and unlinking particles.
    *   **State Update:** Modifying particle states, triggering entangled state updates.
    *   **Collapse Management:** Finalizing particle states and entanglement.
    *   **Permissions:** Delegating collapse rights.
    *   **Scheduled & Event Triggers:** Setting up automatic or external collapse triggers.
    *   **View Functions:** Querying contract state, particle details, entanglement info.
    *   **Utility:** Contract version, metadata hash.

*   **Function Summary:**

    1.  `constructor()`: Initializes the contract owner.
    2.  `createParticle(uint256 initialState, uint256 conditionValue)`: Mints a new particle with an initial state and a condition value.
    3.  `entangleParticles(uint256 particleId1, uint256 particleId2, EntanglementType linkType, uint256 linkConditionValue)`: Creates an entanglement link between two *uncollapsed* particles.
    4.  `disentangleParticles(uint256 particleId1)`: Removes the entanglement link associated with particleId1 (and thus particleId2). Only possible before collapse.
    5.  `updateParticleState(uint256 particleId, uint256 newState)`: Updates the state of a particle. If the particle is entangled, the state of its paired particle is automatically updated based on the entanglement type and condition value. Requires particle ownership.
    6.  `collapseParticle(uint256 particleId)`: Triggers the collapse process for a particle. This finalizes its state and, if entangled, the state of its pair. Prevents further updates or entanglement. Requires ownership or delegated permission.
    7.  `grantCollapsePermission(uint256 particleId, address user)`: Allows a specific user to call `collapseParticle` on a particle owned by the caller.
    8.  `revokeCollapsePermission(uint256 particleId, address user)`: Revokes previously granted collapse permission.
    9.  `transferParticleOwnership(uint256 particleId, address newOwner)`: Transfers ownership of a particle. Standard ERC-721 like transfer logic.
    10. `scheduleCollapse(uint256 particleId, uint256 timestamp)`: Schedules a particle's collapse to happen automatically at a future timestamp. Requires ownership.
    11. `cancelScheduledCollapse(uint256 particleId)`: Cancels a previously scheduled collapse. Requires ownership.
    12. `triggerScheduledCollapse(uint256 particleId)`: Can be called by anyone to trigger a collapse if the scheduled time has passed.
    13. `setEventTriggerHash(uint256 particleId, bytes32 eventHash)`: Sets a hash representing an off-chain event required to trigger collapse. Requires ownership.
    14. `triggerCollapseByEvent(uint256 particleId, bytes32 providedHash)`: Triggers collapse if the provided hash matches the stored event trigger hash for the particle.
    15. `getParticle(uint256 particleId)`: View function to retrieve all details of a particle.
    16. `getParticleState(uint256 particleId)`: View function to get just the current state of a particle.
    17. `getParticleStatus(uint256 particleId)`: View function summarizing if a particle is entangled and/or collapsed.
    18. `getEntangledPairId(uint256 particleId)`: View function to get the ID of the particle entangled with the given particle. Returns 0 if not entangled.
    19. `getEntanglementLink(uint256 particleId)`: View function to get details of the entanglement link associated with a particle.
    20. `isParticleCollapsed(uint256 particleId)`: View function checking collapse status.
    21. `isEntangled(uint256 particleId)`: View function checking entanglement status.
    22. `isAllowedCollapser(uint256 particleId, address user)`: View function checking if a user has collapse permission.
    23. `getTotalParticles()`: View function returning the total number of particles created.
    24. `getTotalCollapsedParticles()`: View function returning the total number of *collapsed* particles (counting each pair as two).
    25. `getParticlesByOwner(address owner)`: View function returning a list of particle IDs owned by an address. (Note: Expensive for owners with many particles).
    26. `getScheduledCollapseTime(uint256 particleId)`: View function returning the timestamp of a scheduled collapse, or 0 if none.
    27. `getEventTriggerHash(uint256 particleId)`: View function returning the stored event trigger hash, or bytes32(0) if none.
    28. `getVersion()`: View function returning the contract version.
    29. `setContractMetadataHash(bytes32 metadataHash)`: Owner-only function to set a hash linking to off-chain contract metadata.
    30. `getContractMetadataHash()`: View function returning the contract metadata hash.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementRegistry
 * @dev A conceptual smart contract simulating quantum entanglement and state collapse
 *      between abstract on-chain entities ("Particles"). Particles can be linked
 *      such that updating one forces a specific update on its entangled partner.
 *      Particles and their entanglement links can be finalized through a "collapse" process.
 *      Includes features like delegated collapse, scheduled collapse, and event-triggered collapse.
 */

contract QuantumEntanglementRegistry {

    // --- Outline & Function Summary ---
    // (See outline above the code for a detailed summary)

    // --- Data Structures ---

    enum EntanglementType {
        NONE, // Should not be used in an active link
        EQUAL_STATE,
        SUM_DEPENDENCY,      // state2 = state1 + conditionValue
        MODULO_DEPENDENCY    // state2 = state1 % conditionValue
    }

    struct Particle {
        uint256 id;
        address owner;
        uint256 state;
        uint256 creationTimestamp;
        bool isCollapsed;
        uint256 collapseTimestamp;
        bool isEntangled;
        uint256 entanglementLinkId; // ID of the link struct this particle is part of
        uint256 conditionValue;     // Parameter for entanglement logic (e.g., the value in SUM/MODULO)
    }

    struct EntanglementLink {
        uint256 id;
        uint256 particle1Id;
        uint256 particle2Id;
        EntanglementType linkType;
        uint256 conditionValue; // Value applied to the *first* particle's state to determine the *second*'s state
        bool isActive;
    }

    // --- State Variables ---

    address public owner;
    uint256 private _particleCounter;
    uint256 private _linkCounter;
    uint256 private _totalCollapsedParticles;
    bytes32 public contractMetadataHash;

    // Mappings to store data
    mapping(uint256 => Particle) public particles;
    mapping(address => uint256[]) private _ownerParticles; // Stores list of particle IDs for each owner (expensive lookup for many particles)
    mapping(uint256 => EntanglementLink) public entanglementLinks;
    mapping(uint256 => uint256) private _particleToEntanglementLinkId; // particleId => linkId

    // Collapse permissions
    mapping(uint256 => mapping(address => bool)) public allowedCollapsers;

    // Scheduled collapse
    mapping(uint256 => uint256) public scheduledCollapses; // particleId => timestamp

    // Event-triggered collapse
    mapping(uint256 => bytes32) public eventTriggerHashes; // particleId => requiredHash

    // Contract version
    string public constant VERSION = "1.0.0";

    // --- Events ---

    event ParticleCreated(uint256 indexed particleId, address indexed owner, uint256 initialState, uint256 conditionValue);
    event ParticlesEntangled(uint256 indexed linkId, uint256 indexed particle1Id, uint256 indexed particle2Id, EntanglementType linkType, uint256 conditionValue);
    event ParticlesDisentangled(uint256 indexed linkId, uint256 indexed particle1Id, uint256 indexed particle2Id);
    event ParticleStateUpdated(uint256 indexed particleId, uint256 oldState, uint256 newState, bool triggeredByEntanglement);
    event ParticleCollapsed(uint256 indexed particleId, address indexed triggeredBy);
    event CollapsePermissionGranted(uint256 indexed particleId, address indexed owner, address indexed user);
    event CollapsePermissionRevoked(uint256 indexed particleId, address indexed owner, address indexed user);
    event OwnershipTransferred(uint256 indexed particleId, address indexed oldOwner, address indexed newOwner);
    event CollapseScheduled(uint256 indexed particleId, uint256 timestamp);
    event CollapseScheduleCancelled(uint256 indexed particleId);
    event EventTriggerHashSet(uint256 indexed particleId, bytes32 eventHash);
    event ContractMetadataHashSet(bytes32 metadataHash);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier whenParticleExists(uint256 particleId) {
        require(particleId > 0 && particleId <= _particleCounter, "Particle does not exist");
        _;
    }

    modifier whenParticleNotCollapsed(uint256 particleId) {
        require(!particles[particleId].isCollapsed, "Particle is already collapsed");
        _;
    }

    modifier whenParticleOwner(uint256 particleId) {
        require(particles[particleId].owner == msg.sender, "Not particle owner");
        _;
    }

    modifier whenParticleEntangled(uint256 particleId) {
        require(particles[particleId].isEntangled, "Particle is not entangled");
        _;
        // Also check the link is active, though isEntangled implies this typically
        require(entanglementLinks[particles[particleId].entanglementLinkId].isActive, "Entanglement link is not active");
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        _particleCounter = 0;
        _linkCounter = 0;
        _totalCollapsedParticles = 0;
    }

    // --- Particle Management ---

    /**
     * @dev Creates a new quantum particle.
     * @param initialState The initial state value for the particle.
     * @param conditionValue A value potentially used in entanglement dependency calculations involving this particle.
     * @return The ID of the newly created particle.
     */
    function createParticle(uint256 initialState, uint256 conditionValue)
        public
        returns (uint256)
    {
        _particleCounter++;
        uint256 newParticleId = _particleCounter;

        particles[newParticleId] = Particle({
            id: newParticleId,
            owner: msg.sender,
            state: initialState,
            creationTimestamp: block.timestamp,
            isCollapsed: false,
            collapseTimestamp: 0,
            isEntangled: false,
            entanglementLinkId: 0,
            conditionValue: conditionValue
        });

        _ownerParticles[msg.sender].push(newParticleId);

        emit ParticleCreated(newParticleId, msg.sender, initialState, conditionValue);

        return newParticleId;
    }

    /**
     * @dev Transfers ownership of a particle.
     * @param particleId The ID of the particle to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferParticleOwnership(uint256 particleId, address newOwner)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = particles[particleId].owner;
        particles[particleId].owner = newOwner;

        // Remove from old owner's list (expensive)
        uint256[] storage oldOwnerList = _ownerParticles[oldOwner];
        for (uint256 i = 0; i < oldOwnerList.length; i++) {
            if (oldOwnerList[i] == particleId) {
                oldOwnerList[i] = oldOwnerList[oldOwnerList.length - 1];
                oldOwnerList.pop();
                break;
            }
        }

        // Add to new owner's list
        _ownerParticles[newOwner].push(particleId);

        // Clear collapse permissions granted by the old owner
        delete allowedCollapsers[particleId];

        emit OwnershipTransferred(particleId, oldOwner, newOwner);
    }

    // --- Entanglement Management ---

    /**
     * @dev Creates an entanglement link between two uncollapsed particles.
     *      Ownership of both particles is required.
     * @param particleId1 The ID of the first particle.
     * @param particleId2 The ID of the second particle.
     * @param linkType The type of entanglement dependency between the two particles.
     * @param linkConditionValue A value used in the dependency calculation, specific to this link.
     */
    function entangleParticles(
        uint256 particleId1,
        uint256 particleId2,
        EntanglementType linkType,
        uint256 linkConditionValue
    )
        public
        whenParticleExists(particleId1)
        whenParticleExists(particleId2)
        whenParticleOwner(particleId1) // Assumes owner of particle1 must be owner of particle2 for entanglement
        whenParticleNotCollapsed(particleId1)
        whenParticleNotCollapsed(particleId2)
    {
        require(particleId1 != particleId2, "Cannot entangle a particle with itself");
        require(!particles[particleId2].isEntangled, "Particle 2 is already entangled");
        require(!particles[particleId1].isEntangled, "Particle 1 is already entangled");
        require(particles[particleId1].owner == particles[particleId2].owner, "Particles must have the same owner to be entangled"); // Simplified assumption
        require(linkType != EntanglementType.NONE, "Invalid entanglement type");

        _linkCounter++;
        uint256 newLinkId = _linkCounter;

        entanglementLinks[newLinkId] = EntanglementLink({
            id: newLinkId,
            particle1Id: particleId1,
            particle2Id: particleId2,
            linkType: linkType,
            conditionValue: linkConditionValue,
            isActive: true
        });

        particles[particleId1].isEntangled = true;
        particles[particleId1].entanglementLinkId = newLinkId;
        particles[particleId2].isEntangled = true;
        particles[particleId2].entanglementLinkId = newLinkId;

        _particleToEntanglementLinkId[particleId1] = newLinkId;
        _particleToEntanglementLinkId[particleId2] = newLinkId;

        // Ensure initial state consistency based on the link type
        _updateEntangledState(particleId1, particles[particleId1].state, false);


        emit ParticlesEntangled(newLinkId, particleId1, particleId2, linkType, linkConditionValue);
    }

    /**
     * @dev Removes an active entanglement link associated with a particle.
     *      Requires particle ownership and is only possible before collapse.
     * @param particleId The ID of one of the particles in the link.
     */
    function disentangleParticles(uint256 particleId)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
        whenParticleEntangled(particleId)
    {
        uint256 linkId = particles[particleId].entanglementLinkId;
        EntanglementLink storage link = entanglementLinks[linkId];
        require(link.isActive, "Entanglement link is not active");

        uint256 particleId1 = link.particle1Id;
        uint256 particleId2 = link.particle2Id;

        link.isActive = false;

        particles[particleId1].isEntangled = false;
        particles[particleId1].entanglementLinkId = 0;
        _particleToEntanglementLinkId[particleId1] = 0;

        particles[particleId2].isEntangled = false;
        particles[particleId2].entanglementLinkId = 0;
        _particleToEntanglementLinkId[particleId2] = 0;

        emit ParticlesDisentangled(linkId, particleId1, particleId2);
    }

    // --- State Update ---

    /**
     * @dev Updates the state of a particle. If the particle is entangled,
     *      the state of its pair is automatically updated based on the link type.
     *      Requires particle ownership.
     * @param particleId The ID of the particle to update.
     * @param newState The new state value.
     */
    function updateParticleState(uint256 particleId, uint256 newState)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        uint256 oldState = particles[particleId].state;
        particles[particleId].state = newState;

        emit ParticleStateUpdated(particleId, oldState, newState, false);

        if (particles[particleId].isEntangled) {
            _updateEntangledState(particleId, newState, true);
        }
    }

    /**
     * @dev Internal function to update the state of the entangled pair.
     * @param updatedParticleId The ID of the particle whose state was just updated.
     * @param updatedParticleNewState The new state of the updated particle.
     * @param triggeredByUpdate Flag indicating if this was triggered by a user calling updateParticleState.
     */
    function _updateEntangledState(uint256 updatedParticleId, uint256 updatedParticleNewState, bool triggeredByUpdate) private {
        uint256 linkId = particles[updatedParticleId].entanglementLinkId;
        EntanglementLink storage link = entanglementLinks[linkId];

        // Find the other particle in the pair
        uint256 otherParticleId = (link.particle1Id == updatedParticleId) ? link.particle2Id : link.particle1Id;

        // Only update if the other particle is not collapsed
        if (!particles[otherParticleId].isCollapsed) {
            uint256 requiredOtherState;
            // Calculate the required state for the other particle based on the link type and condition value
            // The link's conditionValue applies to the state calculation *from* particle1 to particle2
            uint256 stateFromP1 = (link.particle1Id == updatedParticleId) ? updatedParticleNewState : particles[link.particle1Id].state;
            uint256 stateFromP2 = (link.particle2Id == updatedParticleId) ? updatedParticleNewState : particles[link.particle2Id].state;


            if (link.linkType == EntanglementType.EQUAL_STATE) {
                 // Both states must be equal to the state of the particle that was just updated
                 requiredOtherState = updatedParticleNewState;
            } else if (link.linkType == EntanglementType.SUM_DEPENDENCY) {
                // state2 = state1 + conditionValue
                // If particle1 was updated, requiredOtherState (particle2) = newState (particle1) + link.conditionValue
                // If particle2 was updated, this dependency type doesn't define how particle1 changes based on particle2
                // We enforce that the update propagates *from* particle1
                require(link.particle1Id == updatedParticleId, "SUM_DEPENDENCY updates must originate from particle1");
                // unchecked is used for potential overflow, as this is a demo of the concept
                unchecked {
                    requiredOtherState = updatedParticleNewState + link.conditionValue;
                }
            } else if (link.linkType == EntanglementType.MODULO_DEPENDENCY) {
                 // state2 = state1 % conditionValue
                 // Updates must originate from particle1
                 require(link.particle1Id == updatedParticleId, "MODULO_DEPENDENCY updates must originate from particle1");
                 require(link.conditionValue > 0, "Condition value for MODULO_DEPENDENCY must be > 0");
                 requiredOtherState = updatedParticleNewState % link.conditionValue;
            } else {
                 // Should not happen with valid linkType
                 revert("Unknown entanglement type");
            }

            // Apply the required state to the other particle
            uint256 oldOtherState = particles[otherParticleId].state;
            particles[otherParticleId].state = requiredOtherState;
             emit ParticleStateUpdated(otherParticleId, oldOtherState, requiredOtherState, true);
        }
    }


    // --- Collapse Management ---

    /**
     * @dev Triggers the collapse process for a particle and its entangled pair (if any).
     *      Finalizes their states and prevents further state changes or entanglement.
     *      Can be called by the owner or an allowed collapser.
     * @param particleId The ID of the particle to collapse.
     */
    function collapseParticle(uint256 particleId)
        public
        whenParticleExists(particleId)
        whenParticleNotCollapsed(particleId)
    {
        require(
            particles[particleId].owner == msg.sender || allowedCollapsers[particleId][msg.sender],
            "Not authorized to collapse this particle"
        );

        _initiateCollapse(particleId, msg.sender);
    }

     /**
     * @dev Internal function to handle the collapse logic for a particle and its pair.
     * @param particleId The ID of the particle initiating the collapse.
     * @param triggeredBy The address that initiated the collapse.
     */
    function _initiateCollapse(uint256 particleId, address triggeredBy) private {
         // Ensure it's not already collapsed (double check in case state changed between checks)
        require(!particles[particleId].isCollapsed, "Particle is already collapsed");

        particles[particleId].isCollapsed = true;
        particles[particleId].collapseTimestamp = block.timestamp;
        _totalCollapsedParticles++;

        emit ParticleCollapsed(particleId, triggeredBy);

        if (particles[particleId].isEntangled) {
            uint256 linkId = particles[particleId].entanglementLinkId;
            EntanglementLink storage link = entanglementLinks[linkId];
            require(link.isActive, "Entanglement link is not active during collapse initiation");

            uint256 otherParticleId = (link.particle1Id == particleId) ? link.particle2Id : link.particle1Id;

            // Collapse the other particle if it's not already collapsed
            if (!particles[otherParticleId].isCollapsed) {
                 // Ensure consistency before final collapse
                 // We re-run the state update logic based on the first particle's *final* state
                _updateEntangledState(particleId, particles[particleId].state, false);

                particles[otherParticleId].isCollapsed = true;
                particles[otherParticleId].collapseTimestamp = block.timestamp;
                _totalCollapsedParticles++;

                emit ParticleCollapsed(otherParticleId, triggeredBy);
            }

            // Regardless of whether the other particle was already collapsed, the link becomes inactive
            link.isActive = false; // Link is broken upon collapse
        }

        // Clean up scheduled/event triggers upon collapse
        delete scheduledCollapses[particleId];
        delete eventTriggerHashes[particleId];
        // We don't delete permissions, they just become irrelevant for a collapsed particle

    }

    // --- Permissions ---

    /**
     * @dev Grants permission to a specific user to call `collapseParticle` on a particle owned by the caller.
     * @param particleId The ID of the particle.
     * @param user The address to grant permission to.
     */
    function grantCollapsePermission(uint256 particleId, address user)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        require(user != address(0), "User cannot be zero address");
        allowedCollapsers[particleId][user] = true;
        emit CollapsePermissionGranted(particleId, msg.sender, user);
    }

    /**
     * @dev Revokes previously granted collapse permission for a specific user on a particle.
     * @param particleId The ID of the particle.
     * @param user The address to revoke permission from.
     */
    function revokeCollapsePermission(uint256 particleId, address user)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        allowedCollapsers[particleId][user] = false;
        emit CollapsePermissionRevoked(particleId, msg.sender, user);
    }

    // --- Scheduled & Event Triggers ---

    /**
     * @dev Schedules a particle's collapse to happen automatically at a future timestamp.
     *      Requires particle ownership. Overwrites any existing scheduled collapse.
     * @param particleId The ID of the particle to schedule collapse for.
     * @param timestamp The future Unix timestamp when the collapse should be triggered.
     */
    function scheduleCollapse(uint256 particleId, uint256 timestamp)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        scheduledCollapses[particleId] = timestamp;
        emit CollapseScheduled(particleId, timestamp);
    }

    /**
     * @dev Cancels a previously scheduled collapse for a particle.
     *      Requires particle ownership.
     * @param particleId The ID of the particle.
     */
    function cancelScheduledCollapse(uint256 particleId)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        delete scheduledCollapses[particleId];
        emit CollapseScheduleCancelled(particleId);
    }

    /**
     * @dev Can be called by anyone to trigger a particle collapse if its scheduled time has passed.
     * @param particleId The ID of the particle.
     */
    function triggerScheduledCollapse(uint256 particleId)
        public
        whenParticleExists(particleId)
        whenParticleNotCollapsed(particleId)
    {
        uint256 scheduledTime = scheduledCollapses[particleId];
        require(scheduledTime > 0, "No collapse scheduled for this particle");
        require(block.timestamp >= scheduledTime, "Scheduled time has not yet passed");

        // Delete schedule before collapsing to prevent re-trigger
        delete scheduledCollapses[particleId];

        _initiateCollapse(particleId, msg.sender);
    }

     /**
     * @dev Sets a hash representing an off-chain event required to trigger collapse.
     *      Requires particle ownership. Overwrites any existing event trigger hash.
     * @param particleId The ID of the particle.
     * @param eventHash The hash representing the required off-chain event (e.g., keccak256 of event data).
     */
    function setEventTriggerHash(uint256 particleId, bytes32 eventHash)
        public
        whenParticleExists(particleId)
        whenParticleOwner(particleId)
        whenParticleNotCollapsed(particleId)
    {
        eventTriggerHashes[particleId] = eventHash;
        emit EventTriggerHashSet(particleId, eventHash);
    }


    /**
     * @dev Triggers particle collapse if the provided hash matches the stored event trigger hash.
     * @param particleId The ID of the particle.
     * @param providedHash The hash provided by the caller, intended to prove the event occurred off-chain.
     */
    function triggerCollapseByEvent(uint256 particleId, bytes32 providedHash)
        public
        whenParticleExists(particleId)
        whenParticleNotCollapsed(particleId)
    {
        bytes32 requiredHash = eventTriggerHashes[particleId];
        require(requiredHash != bytes32(0), "No event trigger hash set for this particle");
        require(providedHash == requiredHash, "Provided hash does not match required event trigger hash");

        // Delete trigger hash before collapsing
        delete eventTriggerHashes[particleId];

        _initiateCollapse(particleId, msg.sender);
    }


    // --- View Functions ---

    /**
     * @dev Retrieves full details of a particle.
     * @param particleId The ID of the particle.
     * @return A tuple containing all particle properties.
     */
    function getParticle(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (
            uint256 id,
            address owner,
            uint256 state,
            uint256 creationTimestamp,
            bool isCollapsed,
            uint256 collapseTimestamp,
            bool isEntangled,
            uint256 entanglementLinkId,
            uint256 conditionValue
        )
    {
        Particle storage p = particles[particleId];
        return (
            p.id,
            p.owner,
            p.state,
            p.creationTimestamp,
            p.isCollapsed,
            p.collapseTimestamp,
            p.isEntangled,
            p.entanglementLinkId,
            p.conditionValue
        );
    }

    /**
     * @dev Gets the current state of a particle.
     * @param particleId The ID of the particle.
     * @return The current state value.
     */
    function getParticleState(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (uint256)
    {
        return particles[particleId].state;
    }

     /**
     * @dev Gets the creation timestamp of a particle.
     * @param particleId The ID of the particle.
     * @return The creation timestamp.
     */
    function getParticleCreationTimestamp(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (uint256)
    {
        return particles[particleId].creationTimestamp;
    }

    /**
     * @dev Gets the collapse timestamp of a particle. Returns 0 if not collapsed.
     * @param particleId The ID of the particle.
     * @return The collapse timestamp.
     */
    function getParticleCollapseTimestamp(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (uint256)
    {
        return particles[particleId].collapseTimestamp;
    }

    /**
     * @dev Summarizes the entanglement and collapse status of a particle.
     * @param particleId The ID of the particle.
     * @return isEntangled, isCollapsed booleans.
     */
    function getParticleStatus(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (bool isEntangledStatus, bool isCollapsedStatus)
    {
        Particle storage p = particles[particleId];
        return (p.isEntangled, p.isCollapsed);
    }

    /**
     * @dev Gets the ID of the particle entangled with the given particle.
     * @param particleId The ID of the particle.
     * @return The ID of the entangled particle, or 0 if not entangled.
     */
    function getEntangledPairId(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (uint256)
    {
        if (!particles[particleId].isEntangled) {
            return 0;
        }
        uint256 linkId = particles[particleId].entanglementLinkId;
        EntanglementLink storage link = entanglementLinks[linkId];
        return (link.particle1Id == particleId) ? link.particle2Id : link.particle1Id;
    }

     /**
     * @dev Gets the details of the entanglement link associated with a particle.
     * @param particleId The ID of the particle.
     * @return A tuple containing link ID, particle1 ID, particle2 ID, link type, condition value, and active status.
     *         Returns default values (0, address(0), etc.) if particle not entangled or link inactive.
     */
    function getEntanglementLink(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (
            uint256 linkId,
            uint256 particle1Id,
            uint256 particle2Id,
            EntanglementType linkType,
            uint256 conditionValue,
            bool isActive
        )
    {
         if (!particles[particleId].isEntangled) {
             return (0, 0, 0, EntanglementType.NONE, 0, false);
         }
         uint256 linkIdInternal = particles[particleId].entanglementLinkId;
         EntanglementLink storage link = entanglementLinks[linkIdInternal];
         return (
             link.id,
             link.particle1Id,
             link.particle2Id,
             link.linkType,
             link.conditionValue,
             link.isActive
         );
    }


    /**
     * @dev Checks if a particle is collapsed.
     * @param particleId The ID of the particle.
     * @return True if collapsed, false otherwise.
     */
    function isParticleCollapsed(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (bool)
    {
        return particles[particleId].isCollapsed;
    }

    /**
     * @dev Checks if a particle is currently entangled via an active link.
     * @param particleId The ID of the particle.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (bool)
    {
        return particles[particleId].isEntangled;
    }

    /**
     * @dev Checks if a user has been granted permission to collapse a particle.
     * @param particleId The ID of the particle.
     * @param user The address to check.
     * @return True if the user has permission, false otherwise.
     */
    function isAllowedCollapser(uint256 particleId, address user)
        public
        view
        whenParticleExists(particleId)
        returns (bool)
    {
        // Owner always has permission, but this function specifically checks delegated permission
        return allowedCollapsers[particleId][user];
    }


    /**
     * @dev Gets the total number of particles created.
     * @return The total particle count.
     */
    function getTotalParticles() public view returns (uint256) {
        return _particleCounter;
    }

    /**
     * @dev Gets the total number of particles that have undergone collapse.
     *      (Counts each particle, so an entangled pair counts as 2).
     * @return The total count of collapsed particles.
     */
    function getTotalCollapsedParticles() public view returns (uint256) {
        return _totalCollapsedParticles;
    }

    /**
     * @dev Gets a list of particle IDs owned by an address.
     *      NOTE: This function can be very expensive gas-wise if an owner has many particles.
     *      Not suitable for owners with thousands of particles in production.
     * @param owner The address whose particles to retrieve.
     * @return An array of particle IDs.
     */
    function getParticlesByOwner(address owner) public view returns (uint256[] memory) {
        return _ownerParticles[owner];
    }

    /**
     * @dev Gets the scheduled collapse time for a particle.
     * @param particleId The ID of the particle.
     * @return The timestamp, or 0 if no collapse is scheduled.
     */
    function getScheduledCollapseTime(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (uint256)
    {
        return scheduledCollapses[particleId];
    }

    /**
     * @dev Gets the event trigger hash set for a particle.
     * @param particleId The ID of the particle.
     * @return The hash, or bytes32(0) if no hash is set.
     */
    function getEventTriggerHash(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (bytes32)
    {
        return eventTriggerHashes[particleId];
    }

     /**
     * @dev Gets the entanglement type of the link associated with a particle.
     * @param particleId The ID of the particle.
     * @return The EntanglementType, or NONE if not entangled.
     */
    function getEntanglementType(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (EntanglementType)
    {
        if (!particles[particleId].isEntangled) {
            return EntanglementType.NONE;
        }
        uint256 linkId = particles[particleId].entanglementLinkId;
        return entanglementLinks[linkId].linkType;
    }

     /**
     * @dev Gets the condition value of the entanglement link associated with a particle.
     * @param particleId The ID of the particle.
     * @return The condition value, or 0 if not entangled or link has no relevant condition.
     */
    function getEntanglementConditionValue(uint256 particleId)
        public
        view
        whenParticleExists(particleId)
        returns (uint256)
    {
        if (!particles[particleId].isEntangled) {
            return 0;
        }
        uint256 linkId = particles[particleId].entanglementLinkId;
        return entanglementLinks[linkId].conditionValue;
    }


    // --- Utility Functions ---

    /**
     * @dev Returns the contract version string.
     */
    function getVersion() public view returns (string memory) {
        return VERSION;
    }

    /**
     * @dev Sets a hash linking to off-chain contract metadata (e.g., IPFS hash).
     *      Only callable by the contract owner.
     * @param metadataHash The hash to set.
     */
    function setContractMetadataHash(bytes32 metadataHash) public onlyOwner {
        contractMetadataHash = metadataHash;
        emit ContractMetadataHashSet(metadataHash);
    }

    /**
     * @dev Gets the currently set hash linking to off-chain contract metadata.
     * @return The metadata hash.
     */
    function getContractMetadataHash() public view returns (bytes32) {
        return contractMetadataHash;
    }
}
```