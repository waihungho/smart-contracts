Okay, here is a Solidity smart contract incorporating advanced concepts, focusing on a "Quantum Link Protocol" theme where different on-chain entities (addresses, tokens) can be "entangled" or linked with dynamic properties and consent-based actions.

This protocol is designed to be novel and avoids duplicating standard token/NFT/basic DeFi patterns directly, introducing concepts like dynamic state linking, consent-driven actions between linked parties, and modular link types with potential external logic contracts.

---

**Outline & Function Summary**

**Contract Name:** `QuantumLinkProtocol`

**Description:**
A protocol for creating and managing dynamic, consent-based links (or "entanglements") between various on-chain entities (addresses, ERC-721 tokens, ERC-1155 tokens). Links can have different types with specific properties, dynamic states that linked parties can update, and facilitate multi-party consent for triggered actions. Supports oracle integration for state updates based on off-chain data.

**Core Concepts:**
1.  **Entities:** Addresses, ERC-721 tokens (contract+id), ERC-1155 tokens (contract+id).
2.  **Links (Entanglements):** Connections between two entities. Identified by a unique `linkId`.
3.  **Link Types:** Define properties like consent requirements, state mutability, fee, and potentially point to external logic contracts.
4.  **Dynamic State:** Data associated with an active link that can be updated by linked parties or via oracle.
5.  **Consent Actions:** Mechanisms for linked parties to agree on triggering specific actions.
6.  **Oracle Integration:** Allows off-chain data to influence link states.

**State Variables:**
*   `owner`: Contract owner for admin functions.
*   `paused`: Pausing mechanism.
*   `linkIdCounter`: Counter for generating unique link IDs (alternative to hashing).
*   `idToLink`: Mapping from `linkId` to `Link` struct.
*   `entityToLinks`: Mapping from entity ID (hashed) to list of `linkId`s.
*   `pendingRequests`: Mapping from requester address to list of pending `linkId`s.
*   `linkTypes`: Mapping from `uint256` type ID to `LinkType` struct.
*   `validLinkTypeIds`: Array of registered link type IDs.
*   `linkFeesAccumulated`: Total fees collected.
*   `oracleAddress`: Address of the trusted oracle contract.

**Enums:**
*   `EntityType`: Describes the type of on-chain entity.
*   `LinkStatus`: Describes the current state of a link.

**Structs:**
*   `Entity`: Represents an on-chain entity (type, address, tokenId).
*   `Link`: Represents a connection between two entities (id, entities, type, status, timestamps, state, parameters, consent tracking, etc.).
*   `LinkType`: Defines the properties and behavior of a specific link type.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Prevents execution when the contract is paused.
*   `onlyLinkedParties`: Restricts access to the two entities involved in the link.
*   `onlyOracle`: Restricts access to the registered oracle address.
*   `linkMustExist`: Ensures a link with the given ID exists.
*   `linkMustBeStatus`: Ensures a link is in a specific status.
*   `linkMustBeType`: Ensures a link is of a specific type.

**Events:**
*   `LinkTypeRegistered`: Emitted when a new link type is added.
*   `LinkFeeSet`: Emitted when the base link fee is updated.
*   `LinkRequested`: Emitted when a link request is created.
*   `LinkAccepted`: Emitted when a link request is accepted.
*   `LinkRejected`: Emitted when a link request is rejected.
*   `LinkBroken`: Emitted when a link is terminated.
*   `LinkStateUpdated`: Emitted when a link's dynamic state is modified.
*   `LinkParametersUpdated`: Emitted when a link's parameters are changed.
*   `ActionProposed`: Emitted when a linked action is proposed.
*   `ConsentRecorded`: Emitted when a party consents to an action.
*   `ActionExecuted`: Emitted when a linked action is successfully executed.
*   `OracleRequestedForLink`: Emitted when an oracle update is requested for a link.
*   `OracleUpdateReceived`: Emitted when an oracle provides data for a link.
*   `FeesWithdrawn`: Emitted when fees are withdrawn.
*   `Paused`: Emitted when the contract is paused.
*   `Unpaused`: Emitted when the contract is unpaused.

**Functions (Total: 28)**

**Admin & Protocol Management:**
1.  `constructor()`: Initializes the contract owner.
2.  `registerLinkType(uint256 typeId, LinkType memory linkType)`: Registers or updates a link type definition (Owner only).
3.  `setLinkFee(uint256 typeId, uint256 fee)`: Sets the fee required to initiate a specific link type (Owner only).
4.  `setOracleAddress(address _oracle)`: Sets the trusted oracle contract address (Owner only).
5.  `pauseProtocol()`: Pauses key protocol functions (Owner only).
6.  `unpauseProtocol()`: Unpauses the protocol (Owner only).
7.  `withdrawFees(address payable recipient)`: Allows the owner to withdraw accumulated fees.

**Linking & Lifecycle:**
8.  `createLinkRequest(Entity calldata entityA, Entity calldata entityB, uint256 linkTypeId)`: Initiates a link request between two entities (Pays fee if required). Requires approval/onBehalf execution for non-msg.sender entities/tokens.
9.  `acceptLinkRequest(bytes32 linkId)`: Accepts a pending link request if the caller is the recipient entity.
10. `rejectLinkRequest(bytes32 linkId)`: Rejects a pending link request if the caller is the recipient entity.
11. `breakLink(bytes32 linkId)`: Terminates an active link (Callable by either linked party).

**State & Dynamics:**
12. `setLinkParameters(bytes32 linkId, uint256 strength, uint256 duration)`: Updates custom parameters of an active link (If allowed by LinkType, callable by linked parties). Duration updates affect `expiresAt`.
13. `updateLinkState(bytes32 linkId, bytes calldata newStateData)`: Updates the dynamic state data of an active link (If allowed by LinkType, callable by linked parties).
14. `requestOracleUpdateForLink(bytes32 linkId, bytes calldata oracleQueryData)`: Requests the oracle to provide data for a specific link (Callable by linked parties or others if logic allows).
15. `receiveOracleUpdate(bytes32 linkId, bytes calldata updateData)`: Callback function for the oracle to deliver data, potentially updating link state (Only callable by `oracleAddress`).

**Consent & Actions:**
16. `proposeLinkedAction(bytes32 linkId, bytes32 actionHash, string calldata description)`: Proposes an action related to the link, identified by a hash (Callable by a linked party if LinkType allows actions).
17. `consentLinkedAction(bytes32 linkId, bytes32 actionHash)`: Provides consent for a previously proposed action (Callable by a linked party).
18. `revokeConsent(bytes32 linkId, bytes32 actionHash)`: Revokes prior consent for a proposed action (Callable by a linked party).
19. `executeLinkedAction(bytes32 linkId, bytes32 actionHash)`: Executes the action if all linked parties have consented (Requires external integration or logic contract call - this function primarily checks consent and emits).

**View & Query Functions:**
20. `getLinkDetails(bytes32 linkId)`: Retrieves all details for a specific link.
21. `getLinkState(bytes32 linkId)`: Retrieves the current dynamic state data for a link.
22. `getLinksByEntity(Entity calldata entity)`: Retrieves all link IDs associated with a specific entity.
23. `getPendingLinkRequests(address requester)`: Retrieves all pending link IDs initiated by a specific address.
24. `getLinkTypeDetails(uint256 typeId)`: Retrieves details for a specific registered link type.
25. `getValidLinkTypeIds()`: Retrieves the list of all registered link type IDs.
26. `getLinkFeesAccumulated()`: Gets the total accumulated fees in Ether.
27. `isEntityLinked(Entity calldata entityA, Entity calldata entityB)`: Checks if two specific entities are currently linked.
28. `isLinkedParty(bytes32 linkId, address potentialParty)`: Checks if an address is one of the linked parties for a link.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLinkProtocol
 * @dev A protocol for creating dynamic, consent-based links between on-chain entities.
 * Entities can be addresses, ERC-721 tokens, or ERC-1155 tokens.
 * Links have types defining their properties, dynamic states, and consent-driven actions.
 * Supports oracle integration for state updates.
 */
contract QuantumLinkProtocol {

    // --- Outline & Function Summary (See above) ---

    // --- State Variables ---
    address private owner;
    bool private paused;
    uint256 private linkIdCounter;

    enum EntityType { NONE, ADDRESS, ERC721, ERC1155 }
    enum LinkStatus { PENDING, ACTIVE, BROKEN, REJECTED }

    struct Entity {
        EntityType entityType;
        address entityAddress; // For ADDRESS, ERC721, ERC1155
        uint256 tokenId;       // For ERC721, ERC1155
    }

    struct Link {
        bytes32 id;
        Entity entityA;
        Entity entityB;
        uint256 linkTypeId;
        LinkStatus status;
        uint40 createdAt;
        uint40 expiresAt; // 0 if no expiry
        uint256 strength; // Custom parameter 1
        uint256 parameter2; // Custom parameter 2 (flexibility)
        bytes dynamicState; // Dynamic data blob
        address requester; // Who initiated the request

        // Tracking for consent-based actions
        mapping(bytes32 actionHash => mapping(bytes32 entityId => bool consented)) actionConsents;
        mapping(bytes32 actionHash => uint256 consentCount);
        mapping(bytes32 actionHash => string description); // Optional: description of the action
        bytes32[] proposedActionHashes; // List of proposed actions

        // Allows linking arbitrary data hashes relevant to the link (e.g., off-chain document hashes)
        mapping(bytes32 dataHash => bool associatedData);
        bytes32[] associatedDataHashes;
    }

    struct LinkType {
        bool registered; // True if this type ID is active
        bool requireConsentToAccept; // Does the recipient need to accept?
        bool dynamicStateAllowed; // Can updateLinkState be called?
        bool parametersModifiable; // Can setLinkParameters be called?
        bool actionsAllowed; // Can propose/consent actions?
        uint256 requiredConsentCount; // How many linked parties must consent for an action (e.g., 2 for both)
        uint256 baseFee; // Fee in wei to create this type of link
        address logicContract; // Optional: Address of a contract handling type-specific logic/callbacks
    }

    mapping(bytes32 => Link) public idToLink;
    // Map entity ID (hash of entity type, address, token ID) to a list of link IDs it's involved in
    mapping(bytes32 => bytes32[]) private entityToLinks;
    // Map requester address to pending link requests
    mapping(address => bytes32[]) private pendingRequests;
    // Map link type ID to LinkType configuration
    mapping(uint256 => LinkType) public linkTypes;
    uint256[] public validLinkTypeIds;

    uint256 public linkFeesAccumulated;
    address public oracleAddress; // Trusted oracle address

    // --- Events ---
    event LinkTypeRegistered(uint256 indexed typeId, bool registered, uint256 baseFee, address logicContract);
    event LinkFeeSet(uint256 indexed typeId, uint256 fee);
    event OracleAddressSet(address indexed oracle);
    event LinkRequested(bytes32 indexed linkId, Entity entityA, Entity entityB, uint256 indexed linkTypeId, address indexed requester);
    event LinkAccepted(bytes32 indexed linkId, Entity entityA, Entity entityB);
    event LinkRejected(bytes32 indexed linkId, Entity entityA, Entity entityB);
    event LinkBroken(bytes32 indexed linkId, LinkStatus status, address indexed caller); // Status could be BROKEN or REJECTED/PENDING by caller
    event LinkStateUpdated(bytes32 indexed linkId, bytes newStateData, address indexed updater);
    event LinkParametersUpdated(bytes32 indexed linkId, uint256 strength, uint256 duration, address indexed updater);
    event DataHashAssociated(bytes32 indexed linkId, bytes32 indexed dataHash, address indexed associater);
    event ActionProposed(bytes32 indexed linkId, bytes32 indexed actionHash, string description, address indexed proposer);
    event ConsentRecorded(bytes32 indexed linkId, bytes32 indexed actionHash, address indexed consenter);
    event ConsentRevoked(bytes32 indexed linkId, bytes32 indexed actionHash, address indexed consenter);
    event ActionExecuted(bytes32 indexed linkId, bytes32 indexed actionHash);
    event OracleRequestedForLink(bytes32 indexed linkId, bytes oracleQueryData, address indexed requester);
    event OracleUpdateReceived(bytes32 indexed linkId, bytes updateData, address indexed oracle);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "QPL: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QPL: Paused");
        _;
    }

    modifier linkMustExist(bytes32 _linkId) {
        require(idToLink[_linkId].id != bytes32(0), "QPL: Link does not exist");
        _;
    }

    modifier linkMustBeStatus(bytes32 _linkId, LinkStatus _status) {
        require(idToLink[_linkId].status == _status, "QPL: Invalid link status");
        _;
        }

    modifier linkMustBeType(bytes32 _linkId, uint256 _typeId) {
        require(idToLink[_linkId].linkTypeId == _typeId, "QPL: Invalid link type");
        _;
    }

    modifier onlyLinkedParties(bytes32 _linkId) {
        require(
            _isLinkedParty(_linkId, msg.sender),
            "QPL: Not a linked party"
        );
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QPL: Not the oracle");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        linkIdCounter = 0; // Start link IDs from 1 or use hash approach
         // Using keccak256 for linkId provides uniqueness without a counter state variable, but makes lookup by ID harder.
         // Let's stick to a counter for simpler mapping, but use hash for entity IDs.
    }

    // --- Internal Helpers ---
    /**
     * @dev Generates a unique ID for an Entity based on its type, address, and token ID.
     */
    function _getEntityId(Entity memory entity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(entity.entityType, entity.entityAddress, entity.tokenId));
    }

    /**
     * @dev Checks if an address is one of the parties involved in a link.
     */
    function _isLinkedParty(bytes32 _linkId, address potentialParty) internal view returns (bool) {
        Link storage link = idToLink[_linkId];
        if (link.id == bytes32(0)) return false; // Link doesn't exist

        bool isPartyA = (link.entityA.entityType == EntityType.ADDRESS && link.entityA.entityAddress == potentialParty);
        bool isPartyB = (link.entityB.entityType == EntityType.ADDRESS && link.entityB.entityAddress == potentialParty);

        // Extend this check if ERC721/1155 ownership implies linked party status
        // This requires checking current ownership which is external and expensive/complex.
        // For simplicity, let's assume only ADDRESS types can be the *controlling* party for actions.
        // A more advanced version would require interfaces to check token ownership.
        return isPartyA || isPartyB;
    }

    /**
     * @dev Adds a link ID to an entity's list of links.
     */
    function _addLinkToEntity(bytes32 entityId, bytes32 linkId) internal {
        entityToLinks[entityId].push(linkId);
    }

     /**
     * @dev Removes a link ID from an entity's list of links. (Simple implementation: iterate and remove)
     * Note: Removing from dynamic array can be gas-intensive. For large number of links per entity,
     * a more efficient data structure might be needed (e.g., mapping index to boolean and only iterating valid).
     */
    function _removeLinkFromEntity(bytes32 entityId, bytes32 linkId) internal {
        bytes32[] storage links = entityToLinks[entityId];
        for (uint i = 0; i < links.length; i++) {
            if (links[i] == linkId) {
                links[i] = links[links.length - 1];
                links.pop();
                break;
            }
        }
    }


    // --- Admin & Protocol Management ---

    /**
     * @dev Registers or updates a link type definition. Only owner can call.
     * @param typeId The unique ID for the link type.
     * @param linkType The struct defining the link type's properties.
     */
    function registerLinkType(uint256 typeId, LinkType memory linkType) external onlyOwner {
        bool isNewType = !linkTypes[typeId].registered;
        linkType.registered = true; // Ensure registered flag is true when setting
        linkTypes[typeId] = linkType;
        if (isNewType) {
            validLinkTypeIds.push(typeId);
        }
        emit LinkTypeRegistered(typeId, linkType.registered, linkType.baseFee, linkType.logicContract);
    }

     /**
     * @dev Sets the base fee required to initiate a specific link type. Only owner can call.
     * @param typeId The ID of the link type.
     * @param fee The fee in wei.
     */
    function setLinkFee(uint256 typeId, uint256 fee) external onlyOwner {
         require(linkTypes[typeId].registered, "QPL: Link type not registered");
         linkTypes[typeId].baseFee = fee;
         emit LinkFeeSet(typeId, fee);
     }

    /**
     * @dev Sets the trusted oracle contract address. Only owner can call.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QPL: Oracle address cannot be zero");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /**
     * @dev Pauses the protocol. Prevents new link creations/updates, but allows breaking links.
     * Only owner can call.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Only owner can call.
     */
    function unpauseProtocol() external onlyOwner {
        require(paused, "QPL: Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw accumulated fees.
     * @param payable recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) external onlyOwner {
        uint256 amount = linkFeesAccumulated;
        linkFeesAccumulated = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "QPL: Fee withdrawal failed");
        emit FeesWithdrawn(recipient, amount);
    }

    // --- Linking & Lifecycle ---

    /**
     * @dev Initiates a link request between two entities.
     * Requires payment of the link type's base fee.
     * If the link type requires consent, the status is PENDING. Otherwise, it's ACTIVE immediately.
     * @param entityA The first entity.
     * @param entityB The second entity.
     * @param linkTypeId The ID of the desired link type.
     */
    function createLinkRequest(Entity calldata entityA, Entity calldata entityB, uint256 linkTypeId)
        external
        payable
        whenNotPaused
    {
        require(entityA.entityType != EntityType.NONE && entityB.entityType != EntityType.NONE, "QPL: Invalid entity type");
        require(
            (entityA.entityType != EntityType.ADDRESS || entityA.entityAddress != address(0)) &&
            (entityB.entityType != EntityType.ADDRESS || entityB.entityAddress != address(0)),
            "QPL: Entity address cannot be zero"
        );
         // Add checks here for token entities (e.g., tokenAddress != address(0))
        require(entityA.entityAddress != entityB.entityAddress || (entityA.entityType != entityB.entityType || entityA.tokenId != entityB.tokenId), "QPL: Cannot link entity to itself");

        LinkType storage lType = linkTypes[linkTypeId];
        require(lType.registered, "QPL: Link type not registered");
        require(msg.value >= lType.baseFee, "QPL: Insufficient fee");

        linkFeesAccumulated += msg.value;

        // Generate unique link ID
        bytes32 linkId = keccak256(abi.encodePacked(entityA, entityB, linkTypeId, block.timestamp, msg.sender)); // Using hash for ID too

        Link storage newLink = idToLink[linkId];
        require(newLink.id == bytes32(0), "QPL: Link ID collision or already exists"); // Basic collision check

        newLink.id = linkId;
        newLink.entityA = entityA;
        newLink.entityB = entityB;
        newLink.linkTypeId = linkTypeId;
        newLink.createdAt = uint40(block.timestamp);
        newLink.requester = msg.sender;
        newLink.status = lType.requireConsentToAccept ? LinkStatus.PENDING : LinkStatus.ACTIVE;

        if (newLink.status == LinkStatus.ACTIVE) {
            // If no consent needed, immediately add link to entities
            _addLinkToEntity(_getEntityId(entityA), linkId);
            _addLinkToEntity(_getEntityId(entityB), linkId);
        } else {
            // If consent needed, add to pending requests for the recipient
             // Determine which entity is the recipient (assuming EntityB is the recipient by convention)
            if(entityB.entityType == EntityType.ADDRESS) {
                 pendingRequests[entityB.entityAddress].push(linkId);
            }
            // Add logic for token recipients if necessary, potentially requiring token approval or a different mechanism.
            // For this example, let's primarily handle address recipients for simplicity in pendingRequests mapping.
            // A more advanced version might use a generic mapping for pending requests by recipient Entity ID.
             pendingRequests[_getEntityId(entityB)].push(linkId); // Using entity ID for pending
        }


        emit LinkRequested(linkId, entityA, entityB, linkTypeId, msg.sender);
         if (newLink.status == LinkStatus.ACTIVE) {
            emit LinkAccepted(linkId, entityA, entityB); // Treat immediate activation as acceptance
         }
    }

    /**
     * @dev Accepts a pending link request. Callable by the recipient entity.
     * @param linkId The ID of the pending link request.
     */
    function acceptLinkRequest(bytes32 linkId)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.PENDING)
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.registered, "QPL: Link type not registered"); // Should always be true if link exists
        require(lType.requireConsentToAccept, "QPL: Link type does not require acceptance");

        // Check if msg.sender is the intended recipient entity (assuming EntityB is recipient)
        bytes32 recipientEntityId = _getEntityId(link.entityB);
        require(_getEntityIdFromSender(msg.sender) == recipientEntityId, "QPL: Caller is not the recipient entity");
         // Note: _getEntityIdFromSender is a placeholder - requires mapping msg.sender back to the correct Entity if it's a token or specific address instance.
         // For simplicity here, assumes recipient is an ADDRESS and msg.sender IS that address.

        link.status = LinkStatus.ACTIVE;

        // Add link to entities' lists
        _addLinkToEntity(_getEntityId(link.entityA), linkId);
        _addLinkToEntity(_getEntityId(link.entityB), linkId);

        // Remove from pending requests - simple removal for address recipient
         if (link.entityB.entityType == EntityType.ADDRESS) {
            _removeLinkFromPending(link.entityB.entityAddress, linkId);
         }
          _removeLinkFromPending(_getEntityId(link.entityB), linkId); // Remove from generic pending map


        emit LinkAccepted(linkId, link.entityA, link.entityB);
    }

    /**
     * @dev Helper to map msg.sender to an Entity ID. Simplified assumption.
     * In a real contract, this would need context (e.g., is msg.sender controlling a token being linked?).
     */
    function _getEntityIdFromSender(address sender) internal pure returns(bytes32) {
        // This is a very simplified assumption that the sender is the address entity.
        // More complex logic is needed for token entities controlled by the sender.
        return keccak256(abi.encodePacked(EntityType.ADDRESS, sender, uint256(0)));
    }


     /**
     * @dev Helper to remove a link ID from a pending request list. Simple implementation.
     * Note: Same gas concerns as _removeLinkFromEntity apply.
     */
     function _removeLinkFromPending(bytes32 entityId, bytes32 linkId) internal {
        bytes32[] storage pending = pendingRequests[entityId]; // Use entityId for generic pending
        for (uint i = 0; i < pending.length; i++) {
            if (pending[i] == linkId) {
                pending[i] = pending[pending.length - 1];
                pending.pop();
                break;
            }
        }
     }

    /**
     * @dev Rejects a pending link request. Callable by the recipient entity or the requester.
     * @param linkId The ID of the pending link request.
     */
    function rejectLinkRequest(bytes32 linkId)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.PENDING)
    {
        Link storage link = idToLink[linkId];
        bytes32 entityAId = _getEntityId(link.entityA);
        bytes32 entityBId = _getEntityId(link.entityB);
        bytes32 senderEntityId = _getEntityIdFromSender(msg.sender); // Simplified sender mapping

        require(senderEntityId == entityAId || senderEntityId == entityBId, "QPL: Caller is not involved in the request");

        link.status = LinkStatus.REJECTED;

        // Remove from pending requests (from the recipient's list)
        _removeLinkFromPending(entityBId, linkId); // Assuming B was recipient

        emit LinkRejected(linkId, link.entityA, link.entityB);
    }

    /**
     * @dev Terminates an active link. Callable by either linked party.
     * Can also be called on a PENDING/REJECTED link by the requester to clean up.
     * @param linkId The ID of the link to break.
     */
    function breakLink(bytes32 linkId)
        external
        whenNotPaused
        linkMustExist(linkId)
    {
        Link storage link = idToLink[linkId];
        bytes32 entityAId = _getEntityId(link.entityA);
        bytes32 entityBId = _getEntityId(link.entityB);
        bytes32 senderEntityId = _getEntityIdFromSender(msg.sender); // Simplified sender mapping

        if (link.status == LinkStatus.PENDING) {
             require(senderEntityId == _getEntityId(link.requester) || senderEntityId == entityBId, "QPL: Only requester or recipient can cancel pending");
             // Remove from pending requests if it was pending
             _removeLinkFromPending(entityBId, linkId);
        } else { // Active, Broken (for cleanup), Rejected (for cleanup)
             require(senderEntityId == entityAId || senderEntityId == entityBId, "QPL: Not a linked party");
             if (link.status == LinkStatus.ACTIVE) {
                 // Remove from entity links only if it was active
                _removeLinkFromEntity(entityAId, linkId);
                _removeLinkFromEntity(entityBId, linkId);
             }
        }

        // Set status to BROKEN or keep as REJECTED
        LinkStatus finalStatus = link.status == LinkStatus.PENDING ? LinkStatus.REJECTED : LinkStatus.BROKEN;
        link.status = finalStatus;

        emit LinkBroken(linkId, finalStatus, msg.sender);
    }


    // --- State & Dynamics ---

    /**
     * @dev Updates the custom parameters of an active link.
     * Only callable by linked parties if the LinkType allows parameter modification.
     * @param linkId The ID of the active link.
     * @param strength The new strength value.
     * @param duration The new duration (in seconds). 0 for no expiry.
     */
    function setLinkParameters(bytes32 linkId, uint256 strength, uint256 duration)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE)
        onlyLinkedParties(linkId)
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.parametersModifiable, "QPL: Link type parameters are not modifiable");

        link.strength = strength;
        link.parameter2 = duration; // Using parameter2 to store duration temporarily
        link.expiresAt = (duration > 0) ? uint40(block.timestamp + duration) : uint40(0);

        emit LinkParametersUpdated(linkId, strength, duration, msg.sender);
    }

     /**
      * @dev Associates a data hash with a link. Can be used to link off-chain data or documents.
      * Callable by linked parties.
      * @param linkId The ID of the active link.
      * @param dataHash The hash of the data to associate.
      */
     function associateDataHash(bytes32 linkId, bytes32 dataHash)
         external
         whenNotPaused
         linkMustExist(linkId)
         linkMustBeStatus(linkId, LinkStatus.ACTIVE)
         onlyLinkedParties(linkId)
     {
         Link storage link = idToLink[linkId];
         if (!link.associatedData[dataHash]) {
             link.associatedData[dataHash] = true;
             link.associatedDataHashes.push(dataHash);
             emit DataHashAssociated(linkId, dataHash, msg.sender);
         }
     }


    /**
     * @dev Updates the dynamic state data of an active link.
     * Only callable by linked parties if the LinkType allows dynamic state.
     * @param linkId The ID of the active link.
     * @param newStateData The new bytes data for the state.
     */
    function updateLinkState(bytes32 linkId, bytes calldata newStateData)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE)
        onlyLinkedParties(linkId)
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.dynamicStateAllowed, "QPL: Link type state is not dynamic");

        link.dynamicState = newStateData;

        emit LinkStateUpdated(linkId, newStateData, msg.sender);
    }

    /**
     * @dev Requests the registered oracle to provide data for a specific link.
     * Callable by linked parties, or potentially anyone if the LinkType logic allows.
     * Requires an oracle address to be set.
     * @param linkId The ID of the active link.
     * @param oracleQueryData Specific data/parameters for the oracle query.
     */
    function requestOracleUpdateForLink(bytes32 linkId, bytes calldata oracleQueryData)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE)
        // Could add onlyLinkedParties here, or allow based on LinkType config
        // For this example, let's allow any linked party
         onlyLinkedParties(linkId)
    {
        require(oracleAddress != address(0), "QPL: Oracle address not set");
        // In a real scenario, this would interact with an oracle contract
        // e.g., Chainlink VRF, API call contract.
        // For this example, we just emit an event.
        // A real implementation needs a contract interface for the oracle.
        emit OracleRequestedForLink(linkId, oracleQueryData, msg.sender);

        // If a logic contract is defined for this link type, could call it
        // LinkType storage lType = linkTypes[idToLink[linkId].linkTypeId];
        // if (lType.logicContract != address(0)) {
        //     // Make an external call to the logic contract
        //     // (Requires interface and careful error handling/reentrancy prevention)
        // }
    }

    /**
     * @dev Callback function for the oracle to deliver data and potentially update link state.
     * Only callable by the registered oracle address.
     * @param linkId The ID of the link being updated.
     * @param updateData The data received from the oracle.
     */
    function receiveOracleUpdate(bytes32 linkId, bytes calldata updateData)
        external
        onlyOracle
        whenNotPaused // Oracle might need to update even if paused, depending on use case. Check carefully.
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE) // Only update active links
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.dynamicStateAllowed, "QPL: Link type state is not dynamic"); // Oracle can only update dynamic state types

        // Logic here to interpret updateData and apply it to link.dynamicState
        // This would typically involve decoding the `updateData` based on expected format from oracle queries.
        link.dynamicState = updateData; // Simple assignment

        emit OracleUpdateReceived(linkId, updateData, msg.sender);

        // If a logic contract is defined, could call it after update
        // if (lType.logicContract != address(0)) {
        //     // Call logic contract with update data
        // }
    }


    // --- Consent & Actions ---

    /**
     * @dev Proposes an action that requires consent from linked parties.
     * Callable by a linked party if the LinkType allows actions.
     * The action is identified by a hash (e.g., hash of proposed parameters or external call data).
     * @param linkId The ID of the active link.
     * @param actionHash A unique hash identifying the proposed action.
     * @param description An optional description of the action.
     */
    function proposeLinkedAction(bytes32 linkId, bytes32 actionHash, string calldata description)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE)
        onlyLinkedParties(linkId)
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.actionsAllowed, "QPL: Link type does not allow actions");

        // Check if action already exists for this link
        bool actionExists = false;
        for (uint i = 0; i < link.proposedActionHashes.length; i++) {
            if (link.proposedActionHashes[i] == actionHash) {
                actionExists = true;
                break;
            }
        }
        require(!actionExists, "QPL: Action already proposed");

        link.proposedActionHashes.push(actionHash);
        link.description[actionHash] = description; // Store description
        link.actionConsents[actionHash][_getEntityIdFromSender(msg.sender)] = true; // Auto-consent by proposer
        link.consentCount[actionHash] = 1;

        emit ActionProposed(linkId, actionHash, description, msg.sender);

        // If only 1 consent is needed (requester is enough), trigger execution event
        if (lType.requiredConsentCount == 1) {
             emit ActionExecuted(linkId, actionHash); // Signal immediate execution if 1 consent is enough
            // Potential call to logic contract here
        }
    }

    /**
     * @dev Provides consent for a previously proposed linked action.
     * Callable by a linked party.
     * @param linkId The ID of the active link.
     * @param actionHash The hash of the proposed action.
     */
    function consentLinkedAction(bytes32 linkId, bytes32 actionHash)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE)
        onlyLinkedParties(linkId)
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.actionsAllowed, "QPL: Link type does not allow actions");

         // Check if action was actually proposed
         bool actionFound = false;
         for(uint i=0; i<link.proposedActionHashes.length; i++) {
             if(link.proposedActionHashes[i] == actionHash) {
                 actionFound = true;
                 break;
             }
         }
         require(actionFound, "QPL: Action not proposed for this link");


        bytes32 senderEntityId = _getEntityIdFromSender(msg.sender);
        require(!link.actionConsents[actionHash][senderEntityId], "QPL: Already consented");

        link.actionConsents[actionHash][senderEntityId] = true;
        link.consentCount[actionHash]++;

        emit ConsentRecorded(linkId, actionHash, msg.sender);

        // Check if required consent count is reached
        if (link.consentCount[actionHash] >= lType.requiredConsentCount && lType.requiredConsentCount > 0) {
            // Action is ready to be executed
             emit ActionExecuted(linkId, actionHash); // Signal that the action can be executed
             // Potential call to logic contract here
        }
    }

     /**
      * @dev Revokes consent for a previously proposed linked action.
      * Callable by a linked party who has previously consented.
      * @param linkId The ID of the active link.
      * @param actionHash The hash of the proposed action.
      */
    function revokeConsent(bytes32 linkId, bytes32 actionHash)
         external
         whenNotPaused
         linkMustExist(linkId)
         linkMustBeStatus(linkId, LinkStatus.ACTIVE)
         onlyLinkedParties(linkId)
     {
         Link storage link = idToLink[linkId];
         LinkType storage lType = linkTypes[link.linkTypeId];
         require(lType.actionsAllowed, "QPL: Link type does not allow actions");

         bytes32 senderEntityId = _getEntityIdFromSender(msg.sender);
         require(link.actionConsents[actionHash][senderEntityId], "QPL: No consent recorded");

         link.actionConsents[actionHash][senderEntityId] = false;
         link.consentCount[actionHash]--;

         emit ConsentRevoked(linkId, actionHash, msg.sender);
     }


    /**
     * @dev Executes a linked action if the required consent count is met.
     * This function itself primarily checks consent and emits an event.
     * Actual execution logic would live elsewhere (e.g., in a logic contract or separate system
     * triggered by the ActionExecuted event).
     * Callable by any linked party once consent is met.
     * @param linkId The ID of the active link.
     * @param actionHash The hash of the proposed action.
     */
    function executeLinkedAction(bytes32 linkId, bytes32 actionHash)
        external
        whenNotPaused
        linkMustExist(linkId)
        linkMustBeStatus(linkId, LinkStatus.ACTIVE)
        onlyLinkedParties(linkId) // Could potentially allow anyone to trigger execution once ready
    {
        Link storage link = idToLink[linkId];
        LinkType storage lType = linkTypes[link.linkTypeId];
        require(lType.actionsAllowed, "QPL: Link type does not allow actions");
        require(lType.requiredConsentCount > 0, "QPL: Link type does not require/use consent for actions"); // Avoid executing actions not needing consent via this path

        require(link.consentCount[actionHash] >= lType.requiredConsentCount, "QPL: Not enough consent to execute action");

        // Mark action as executed (or remove it, or store execution timestamp)
        // For simplicity, let's assume an action can only be executed once.
        // We could use a mapping `executedActions[actionHash] => bool`.
        // For now, let's rely on the external system to handle idempotency if needed.

        emit ActionExecuted(linkId, actionHash);

        // Potential call to the logic contract for actual execution
        // if (lType.logicContract != address(0)) {
        //     // Call the logic contract, passing linkId and actionHash
        //     // Interface ILinkLogic { function executeAction(bytes32 linkId, bytes32 actionHash) external; }
        //     // ILinkLogic(lType.logicContract).executeAction(linkId, actionHash);
        //     // Need reentrancy guards if external calls modify state relevant to checks.
        // }
    }

    // --- View & Query Functions ---

    /**
     * @dev Retrieves details for a specific link.
     * @param linkId The ID of the link.
     * @return A tuple containing link details.
     */
    function getLinkDetails(bytes32 linkId)
        external
        view
        linkMustExist(linkId)
        returns (
            bytes32 id,
            Entity memory entityA,
            Entity memory entityB,
            uint256 linkTypeId,
            LinkStatus status,
            uint40 createdAt,
            uint40 expiresAt,
            uint256 strength,
            uint256 parameter2,
            bytes memory dynamicState,
            address requester,
            bytes32[] memory associatedDataHashes
        )
    {
        Link storage link = idToLink[linkId];
        return (
            link.id,
            link.entityA,
            link.entityB,
            link.linkTypeId,
            link.status,
            link.createdAt,
            link.expiresAt,
            link.strength,
            link.parameter2,
            link.dynamicState,
            link.requester,
            link.associatedDataHashes
        );
    }

     /**
      * @dev Gets the hash description for a proposed action.
      * @param linkId The ID of the link.
      * @param actionHash The hash of the action.
      * @return The description string.
      */
     function getActionDescription(bytes32 linkId, bytes32 actionHash)
         external
         view
         linkMustExist(linkId)
         returns (string memory)
     {
        Link storage link = idToLink[linkId];
         return link.description[actionHash];
     }

     /**
      * @dev Gets the consent count for a proposed action.
      * @param linkId The ID of the link.
      * @param actionHash The hash of the action.
      * @return The current number of consents.
      */
     function getActionConsentCount(bytes32 linkId, bytes32 actionHash)
          external
          view
          linkMustExist(linkId)
          returns (uint256)
      {
          Link storage link = idToLink[linkId];
          return link.consentCount[actionHash];
      }

       /**
        * @dev Checks if a specific entity has consented to an action.
        * @param linkId The ID of the link.
        * @param actionHash The hash of the action.
        * @param entity The entity to check consent for.
        * @return True if the entity has consented, false otherwise.
        */
     function hasEntityConsented(bytes32 linkId, bytes32 actionHash, Entity calldata entity)
         external
         view
         linkMustExist(linkId)
         returns (bool)
     {
         Link storage link = idToLink[linkId];
         return link.actionConsents[actionHash][_getEntityId(entity)];
     }


    /**
     * @dev Retrieves the current dynamic state data for a link.
     * @param linkId The ID of the link.
     * @return The dynamic state bytes.
     */
    function getLinkState(bytes32 linkId)
        external
        view
        linkMustExist(linkId)
        returns (bytes memory)
    {
        return idToLink[linkId].dynamicState;
    }

    /**
     * @dev Retrieves all link IDs associated with a specific entity.
     * @param entity The entity to query links for.
     * @return An array of link IDs.
     */
    function getLinksByEntity(Entity calldata entity)
        external
        view
        returns (bytes32[] memory)
    {
        require(entity.entityType != EntityType.NONE, "QPL: Invalid entity type");
        return entityToLinks[_getEntityId(entity)];
    }

    /**
     * @dev Retrieves all pending link IDs for a specific recipient entity (assuming EntityB was the recipient convention).
     * Uses the entity ID mapping for lookup.
     * @param entity The entity that is the potential recipient of links.
     * @return An array of pending link IDs.
     */
    function getPendingLinkRequests(Entity calldata entity)
        external
        view
        returns (bytes32[] memory)
    {
        require(entity.entityType != EntityType.NONE, "QPL: Invalid entity type");
         // Note: This assumes entity mapping for pending requests. If only address mapping used, this needs adjustment.
        return pendingRequests[_getEntityId(entity)];
    }


    /**
     * @dev Retrieves details for a specific registered link type.
     * @param typeId The ID of the link type.
     * @return A tuple containing link type details.
     */
    function getLinkTypeDetails(uint256 typeId)
        external
        view
        returns (
            bool registered,
            bool requireConsentToAccept,
            bool dynamicStateAllowed,
            bool parametersModifiable,
            bool actionsAllowed,
            uint256 requiredConsentCount,
            uint256 baseFee,
            address logicContract
        )
    {
        LinkType storage lType = linkTypes[typeId];
        return (
            lType.registered,
            lType.requireConsentToAccept,
            lType.dynamicStateAllowed,
            lType.parametersModifiable,
            lType.actionsAllowed,
            lType.requiredConsentCount,
            lType.baseFee,
            lType.logicContract
        );
    }

    /**
     * @dev Retrieves the list of all registered link type IDs.
     * @return An array of registered link type IDs.
     */
    function getValidLinkTypeIds() external view returns (uint256[] memory) {
        return validLinkTypeIds;
    }

    /**
     * @dev Gets the total accumulated fees in Ether.
     * @return The total accumulated fees.
     */
    function getLinkFeesAccumulated() external view returns (uint256) {
        return linkFeesAccumulated;
    }

    /**
     * @dev Checks if two specific entities are currently linked (status is ACTIVE).
     * Note: This might iterate through one entity's links, which can be gas-intensive for view functions if an entity has many links.
     * A more efficient check would require storing link existence in a separate mapping `isLinked[entityA_id][entityB_id]`.
     * @param entityA The first entity.
     * @param entityB The second entity.
     * @return True if the entities are actively linked, false otherwise.
     */
    function isEntityLinked(Entity calldata entityA, Entity calldata entityB)
        external
        view
        returns (bool)
    {
        require(entityA.entityType != EntityType.NONE && entityB.entityType != EntityType.NONE, "QPL: Invalid entity type");
        bytes32 entityAId = _getEntityId(entityA);
        bytes32 entityBId = _getEntityId(entityB);

        bytes32[] memory linksA = entityToLinks[entityAId];
        for (uint i = 0; i < linksA.length; i++) {
            bytes32 linkId = linksA[i];
            Link storage link = idToLink[linkId];
            // Check if the other entity in this link is entityB and status is ACTIVE
            if (link.status == LinkStatus.ACTIVE) {
                bytes32 linkedEntityId = _getEntityId(link.entityA.entityType == entityA.entityType && link.entityA.entityAddress == entityA.entityAddress && link.entityA.tokenId == entityA.tokenId ? link.entityB : link.entityA);
                 if (linkedEntityId == entityBId) {
                    return true;
                 }
            }
        }
        return false;
    }

    /**
     * @dev Checks if an address is one of the controlling parties for a link.
     * @param linkId The ID of the link.
     * @param potentialParty The address to check.
     * @return True if the address is a linked party (specifically an ADDRESS type entity), false otherwise.
     */
     function isLinkedParty(bytes32 linkId, address potentialParty)
         external
         view
         linkMustExist(linkId)
         returns (bool)
     {
         // Uses the internal helper function
         return _isLinkedParty(linkId, potentialParty);
     }

    // --- Fallback/Receive ---
    receive() external payable {
        // Allows receiving ether for fees or other purposes
        linkFeesAccumulated += msg.value;
    }
}
```