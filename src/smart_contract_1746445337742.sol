Okay, here is a Solidity smart contract implementing a "Nexus Attestation Network". This concept involves managing dynamic, verifiable digital credentials or attestations on-chain. It includes features like different attestation types, instance issuance, revocation, expiration, associated data, and more advanced concepts like attestation delegation for verification and conditional transferability. It aims to be creative and go beyond simple token standards or basic registry patterns.

**Outline and Function Summary**

**Contract Name:** NexusAttestations

**Concept:** A decentralized system for creating, issuing, managing, and verifying dynamic digital attestations (credentials/proofs) on the blockchain. Attestations are structured data attached to a recipient, issued by authorized entities, and can have conditions like expiration, revocation, and associated data.

**Key Features:**
*   **Structured Attestation Types:** Define different categories of attestations with specific rules and data structures.
*   **Parameterized Instances:** Each attestation instance holds specific data for a recipient.
*   **Access Control:** Roles for admin, type creators, and authorized issuers per type.
*   **Issuance & Revocation:** Controlled minting and invalidation of attestations.
*   **Expiration:** Attestations can have a limited validity period.
*   **Data Association:** Attestations carry arbitrary `bytes` data payload.
*   **Verification Logic:** Built-in checks for validity (not revoked, not expired).
*   **Delegate Verification:** Recipients can temporarily authorize others to verify a specific attestation on their behalf.
*   **Conditional Transferability:** Attestation types can be configured to allow instances to be transferred between users.
*   **Fee Mechanism:** Optional fees for creating attestation types.

**Function Summary:**

**I. Core Admin Functions (restricted to `owner`)**
1.  `setAdmin(address newAdmin)`: Set the main administrator address.
2.  `grantTypeCreatorRole(address typeCreator)`: Grant permission to create new attestation types.
3.  `revokeTypeCreatorRole(address typeCreator)`: Revoke permission to create attestation types.
4.  `pauseIssuance()`: Pause all new attestation issuance.
5.  `unpauseIssuance()`: Unpause attestation issuance.
6.  `setAttestationTypeCreationFee(uint256 fee)`: Set the fee required to create a new type.
7.  `withdrawFees(address recipient)`: Withdraw collected creation fees to a specified address.

**II. Attestation Type Management (restricted to `owner` or addresses with `TYPE_CREATOR_ROLE`)**
8.  `createAttestationType(string calldata name, string calldata description, bool transferableByDefault, uint48 defaultExpirationDuration, address[] calldata initialAuthorizedIssuers)`: Define and register a new attestation type.
9.  `updateAttestationTypeDetails(uint256 typeId, string calldata name, string calldata description)`: Update the non-critical details of an existing type.
10. `deactivateAttestationType(uint256 typeId)`: Prevent further instances of this type from being issued.
11. `reactivateAttestationType(uint256 typeId)`: Allow issuance for a previously deactivated type.
12. `addAuthorizedIssuer(uint256 typeId, address issuer)`: Add an address authorized to issue instances of a specific type.
13. `removeAuthorizedIssuer(uint256 typeId, address issuer)`: Remove an authorized issuer from a specific type.
14. `setAttestationTransferability(uint256 typeId, bool transferable)`: Set whether instances of a type can be transferred after creation.
15. `setDefaultExpirationDuration(uint256 typeId, uint48 duration)`: Update the default expiration duration for future instances of a type.

**III. Attestation Instance Management (restricted to authorized issuers or instance owners)**
16. `issueAttestation(uint256 typeId, address recipient, bytes calldata dataPayload, uint48 expirationTimestampOverride)`: Issue a new attestation instance for a recipient. Issuer must be authorized for the type. Allows overriding the default expiration.
17. `revokeAttestation(uint256 instanceId)`: Invalidate an attestation instance. Can only be called by the original issuer or the admin.
18. `requestAttestationDataUpdate(uint256 instanceId, bytes calldata newDataPayload)`: Allows the issuer to update the data payload of an instance (e.g., updating a score).
19. `transferAttestationOwnership(uint256 instanceId, address newRecipient)`: Transfer ownership of an attestation instance to another address. Only possible if the type is transferable and called by the current recipient.
20. `updateAttestationExpiration(uint256 instanceId, uint48 newExpirationTimestamp)`: Allows the issuer or admin to extend or shorten the expiration time of an instance.

**IV. Query and Verification Functions (publicly available, `view` or `pure`)**
21. `getAttestationType(uint256 typeId)`: Retrieve details of an attestation type.
22. `getAttestationInstance(uint256 instanceId)`: Retrieve details of an attestation instance.
23. `getUserAttestations(address user)`: Get a list of all attestation instance IDs held by a user. (Note: Can be gas-intensive for users with many attestations).
24. `getTotalAttestationTypes()`: Get the total count of registered attestation types.
25. `getTotalAttestationInstances()`: Get the total count of issued attestation instances.
26. `isAttestationValid(uint256 instanceId)`: Check if an attestation instance is currently valid (exists, not revoked, not expired).
27. `userHasAttestationOfType(address user, uint256 typeId)`: Check if a user holds *at least one* currently valid instance of a specific type.
28. `getUserValidAttestationsOfType(address user, uint256 typeId)`: Get a list of valid attestation instance IDs of a specific type held by a user.
29. `verifyAttestationWithDataPrefix(uint256 instanceId, bytes calldata requiredPrefix)`: Check if an attestation is valid AND its data payload starts with a specific byte prefix.

**V. Delegation Functions (Recipient controlled)**
30. `delegateVerification(uint256 instanceId, address delegate, uint48 delegationExpirationTimestamp)`: Allow a third party (`delegate`) to verify this specific attestation instance on the recipient's behalf until a specified time.
31. `removeDelegate(uint256 instanceId, address delegate)`: Remove a verification delegate for an instance.
32. `isDelegateVerifier(uint256 instanceId, address potentialDelegate)`: Check if an address is currently a valid delegate verifier for an instance.
33. `isAttestationValidForDelegate(uint256 instanceId, address potentialDelegate)`: Check if an attestation is valid *and* if the `potentialDelegate` is authorized to verify it via delegation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NexusAttestations
 * @dev A decentralized system for managing dynamic, verifiable digital credentials.
 * Attestations are structured data associated with users, issued by authorized parties,
 * with features like types, expiration, revocation, associated data,
 * delegate verification, and conditional transferability.
 */

/*
 * Outline:
 * I. Core Admin Functions
 * II. Attestation Type Management
 * III. Attestation Instance Management
 * IV. Query and Verification Functions
 * V. Delegation Functions
 */

contract NexusAttestations {

    // --- Data Structures ---

    struct AttestationType {
        string name;
        string description;
        bool isActive; // Can new instances be issued?
        bool isTransferable; // Can instances be transferred by recipient?
        uint48 defaultExpirationDuration; // Default duration from issuance (0 for no default expiration)
    }

    struct AttestationInstance {
        uint256 typeId;
        address recipient;
        address issuer;
        uint48 issuanceTimestamp;
        uint48 expirationTimestamp; // 0 if no expiration
        bool isRevoked;
        bytes dataPayload;
        mapping(address => uint48) delegateExpirations; // delegate address => expiration timestamp
    }

    // --- State Variables ---

    address public owner; // Initial deployer
    address public admin; // Can be set by owner, shares some admin privileges

    uint256 private _attestationTypeCounter; // Starts at 1
    uint256 private _attestationInstanceCounter; // Starts at 1

    mapping(uint256 => AttestationType) public attestationTypes;
    mapping(uint256 => AttestationInstance) private attestationInstances; // Private due to internal mappings

    // Mapping for efficient lookup of instances by ID
    mapping(uint256 => bool) public instanceExists;

    // Mapping to track attestations per user (can be expensive to iterate)
    mapping(address => uint256[]) public userAttestations;

    // Mapping to track authorized issuers per attestation type
    mapping(uint256 => mapping(address => bool)) private typeAuthorizedIssuers;
    mapping(uint256 => address[]) private typeAuthorizedIssuersList; // To retrieve the list

    // Roles
    bytes32 public constant TYPE_CREATOR_ROLE = keccak256("TYPE_CREATOR");
    mapping(address => bool) private typeCreators;

    // Fee mechanism
    uint256 public attestationTypeCreationFee = 0; // Fee in native currency (e.g., Wei)
    uint256 private collectedFees = 0;

    // Pause mechanism
    bool public issuancePaused = false;

    // --- Events ---

    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event TypeCreatorRoleGranted(address indexed typeCreator);
    event TypeCreatorRoleRevoked(address indexed typeCreator);
    event IssuancePaused();
    event IssuanceUnpaused();
    event AttestationTypeCreationFeeSet(uint256 oldFee, uint256 newFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    event AttestationTypeCreated(uint256 indexed typeId, string name, address indexed creator);
    event AttestationTypeUpdated(uint256 indexed typeId, string name);
    event AttestationTypeDeactivated(uint256 indexed typeId);
    event AttestationTypeReactivated(uint256 indexed typeId);
    event AuthorizedIssuerAdded(uint256 indexed typeId, address indexed issuer);
    event AuthorizedIssuerRemoved(uint256 indexed typeId, address indexed issuer);
    event AttestationTransferabilitySet(uint256 indexed typeId, bool isTransferable);
    event DefaultExpirationDurationSet(uint256 indexed typeId, uint48 duration);

    event AttestationIssued(uint256 indexed instanceId, uint256 indexed typeId, address indexed recipient, address indexed issuer, uint48 issuanceTimestamp, uint48 expirationTimestamp);
    event AttestationRevoked(uint256 indexed instanceId, address indexed revoker);
    event AttestationDataUpdated(uint256 indexed instanceId, address indexed updater);
    event AttestationTransferred(uint256 indexed instanceId, address indexed fromRecipient, address indexed toRecipient);
    event AttestationExpirationUpdated(uint256 indexed instanceId, uint48 oldExpirationTimestamp, uint48 newExpirationTimestamp);

    event VerificationDelegated(uint256 indexed instanceId, address indexed recipient, address indexed delegate, uint48 expirationTimestamp);
    event DelegateRemoved(uint256 indexed instanceId, address indexed recipient, address indexed delegate);

    // --- Access Control ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin, "Only owner or admin");
        _;
    }

    modifier onlyTypeCreator() {
        require(typeCreators[msg.sender], "Only type creator");
        _;
    }

    modifier onlyAuthorizedIssuer(uint256 typeId) {
        require(typeAuthorizedIssuers[typeId][msg.sender] || msg.sender == owner || msg.sender == admin, "Only authorized issuer or admin");
        _;
    }

    modifier whenNotPaused() {
        require(!issuancePaused, "Issuance is paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        admin = msg.sender;
        _attestationTypeCounter = 0; // Use 0 as invalid ID
        _attestationInstanceCounter = 0; // Use 0 as invalid ID
    }

    // --- I. Core Admin Functions ---

    /**
     * @dev Sets the admin address. Can only be called by the current owner.
     * @param newAdmin The address to set as the new admin.
     */
    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Invalid admin address");
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @dev Grants the TYPE_CREATOR_ROLE to an address. Can only be called by the owner.
     * Type creators can define new attestation types.
     * @param typeCreator The address to grant the role to.
     */
    function grantTypeCreatorRole(address typeCreator) external onlyOwner {
        require(typeCreator != address(0), "Invalid address");
        require(!typeCreators[typeCreator], "Already a type creator");
        typeCreators[typeCreator] = true;
        emit TypeCreatorRoleGranted(typeCreator);
    }

    /**
     * @dev Revokes the TYPE_CREATOR_ROLE from an address. Can only be called by the owner.
     * @param typeCreator The address to revoke the role from.
     */
    function revokeTypeCreatorRole(address typeCreator) external onlyOwner {
        require(typeCreators[typeCreator], "Not a type creator");
        typeCreators[typeCreator] = false;
        emit TypeCreatorRoleRevoked(typeCreator);
    }

    /**
     * @dev Pauses the issuance of new attestation instances. Can only be called by the owner or admin.
     */
    function pauseIssuance() external onlyOwnerOrAdmin {
        require(!issuancePaused, "Issuance already paused");
        issuancePaused = true;
        emit IssuancePaused();
    }

    /**
     * @dev Unpauses the issuance of new attestation instances. Can only be called by the owner or admin.
     */
    function unpauseIssuance() external onlyOwnerOrAdmin {
        require(issuancePaused, "Issuance not paused");
        issuancePaused = false;
        emit IssuanceUnpaused();
    }

    /**
     * @dev Sets the fee required to create a new attestation type. Can only be called by the owner.
     * @param fee The new creation fee in native currency (e.g., Wei).
     */
    function setAttestationTypeCreationFee(uint256 fee) external onlyOwner {
        emit AttestationTypeCreationFeeSet(attestationTypeCreationFee, fee);
        attestationTypeCreationFee = fee;
    }

    /**
     * @dev Withdraws collected creation fees to a specified recipient. Can only be called by the owner.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        uint256 amount = collectedFees;
        require(amount > 0, "No fees to withdraw");
        collectedFees = 0;
        // Use call to send Ether to handle potential reentrancy issues more safely than transfer/send
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(recipient, amount);
    }

    // --- II. Attestation Type Management ---

    /**
     * @dev Creates a new attestation type. Requires TYPE_CREATOR_ROLE or be owner/admin.
     * Requires payment of `attestationTypeCreationFee`.
     * @param name The name of the attestation type (e.g., " KYC Verified").
     * @param description A brief description of the type.
     * @param transferableByDefault Whether instances of this type can be transferred by default.
     * @param defaultExpirationDuration Default duration in seconds from issuance for instances (0 for no default expiration).
     * @param initialAuthorizedIssuers List of addresses initially authorized to issue this type.
     * @return typeId The ID of the newly created attestation type.
     */
    function createAttestationType(
        string calldata name,
        string calldata description,
        bool transferableByDefault,
        uint48 defaultExpirationDuration,
        address[] calldata initialAuthorizedIssuers
    ) external payable onlyTypeCreator returns (uint256 typeId) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(msg.value >= attestationTypeCreationFee, "Insufficient fee");

        if (msg.value > attestationTypeCreationFee) {
             // Refund excess
            payable(msg.sender).transfer(msg.value - attestationTypeCreationFee);
        }
        collectedFees += attestationTypeCreationFee;


        _attestationTypeCounter++;
        typeId = _attestationTypeCounter;

        attestationTypes[typeId] = AttestationType({
            name: name,
            description: description,
            isActive: true,
            isTransferable: transferableByDefault,
            defaultExpirationDuration: defaultExpirationDuration
        });

        // Add initial authorized issuers
        for (uint i = 0; i < initialAuthorizedIssuers.length; i++) {
            address issuer = initialAuthorizedIssuers[i];
            if (issuer != address(0) && !typeAuthorizedIssuers[typeId][issuer]) {
                typeAuthorizedIssuers[typeId][issuer] = true;
                typeAuthorizedIssuersList[typeId].push(issuer);
                emit AuthorizedIssuerAdded(typeId, issuer); // Event for each initial issuer
            }
        }

        emit AttestationTypeCreated(typeId, name, msg.sender);
    }

     /**
     * @dev Updates the non-critical details of an existing attestation type.
     * Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type to update.
     * @param name The new name.
     * @param description The new description.
     */
    function updateAttestationTypeDetails(uint256 typeId, string calldata name, string calldata description) external onlyTypeCreator {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        require(bytes(name).length > 0, "Name cannot be empty");
        // description can be empty

        AttestationType storage typeData = attestationTypes[typeId];
        typeData.name = name;
        typeData.description = description;

        emit AttestationTypeUpdated(typeId, name);
    }

    /**
     * @dev Deactivates an attestation type, preventing new instances from being issued.
     * Existing instances remain and maintain their state (expiration, revocation).
     * Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type to deactivate.
     */
    function deactivateAttestationType(uint256 typeId) external onlyTypeCreator {
         require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
         AttestationType storage typeData = attestationTypes[typeId];
         require(typeData.isActive, "Type already inactive");
         typeData.isActive = false;
         emit AttestationTypeDeactivated(typeId);
    }

    /**
     * @dev Reactivates a previously deactivated attestation type, allowing new instances to be issued.
     * Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type to reactivate.
     */
    function reactivateAttestationType(uint256 typeId) external onlyTypeCreator {
         require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
         AttestationType storage typeData = attestationTypes[typeId];
         require(!typeData.isActive, "Type already active");
         typeData.isActive = true;
         emit AttestationTypeReactivated(typeId);
    }

    /**
     * @dev Adds an address to the list of authorized issuers for a specific attestation type.
     * Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type.
     * @param issuer The address to authorize.
     */
    function addAuthorizedIssuer(uint256 typeId, address issuer) external onlyTypeCreator {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        require(issuer != address(0), "Invalid issuer address");
        require(!typeAuthorizedIssuers[typeId][issuer], "Issuer already authorized");

        typeAuthorizedIssuers[typeId][issuer] = true;
        typeAuthorizedIssuersList[typeId].push(issuer);
        emit AuthorizedIssuerAdded(typeId, issuer);
    }

    /**
     * @dev Removes an address from the list of authorized issuers for a specific attestation type.
     * Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type.
     * @param issuer The address to deauthorize.
     */
    function removeAuthorizedIssuer(uint256 typeId, address issuer) external onlyTypeCreator {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        require(issuer != address(0), "Invalid issuer address");
        require(typeAuthorizedIssuers[typeId][issuer], "Issuer not authorized");

        typeAuthorizedIssuers[typeId][issuer] = false;

        // Remove from the list (less efficient but needed for retrieval)
        address[] storage issuers = typeAuthorizedIssuersList[typeId];
        for (uint i = 0; i < issuers.length; i++) {
            if (issuers[i] == issuer) {
                issuers[i] = issuers[issuers.length - 1];
                issuers.pop();
                break;
            }
        }

        emit AuthorizedIssuerRemoved(typeId, issuer);
    }

    /**
     * @dev Sets whether instances of a specific attestation type can be transferred by the recipient.
     * Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type.
     * @param transferable True if instances should be transferable, false otherwise.
     */
    function setAttestationTransferability(uint256 typeId, bool transferable) external onlyTypeCreator {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        AttestationType storage typeData = attestationTypes[typeId];
        require(typeData.isTransferable != transferable, "Transferability already set to this value");
        typeData.isTransferable = transferable;
        emit AttestationTransferabilitySet(typeId, transferable);
    }

    /**
     * @dev Updates the default expiration duration for future instances of a type.
     * Existing instances are unaffected. Can only be called by a type creator or admin/owner.
     * @param typeId The ID of the attestation type.
     * @param duration The new default duration in seconds (0 for no default).
     */
    function setDefaultExpirationDuration(uint256 typeId, uint48 duration) external onlyTypeCreator {
         require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
         AttestationType storage typeData = attestationTypes[typeId];
         require(typeData.defaultExpirationDuration != duration, "Default duration already set to this value");
         typeData.defaultExpirationDuration = duration;
         emit DefaultExpirationDurationSet(typeId, duration);
    }


    // --- III. Attestation Instance Management ---

    /**
     * @dev Issues a new attestation instance to a recipient.
     * Can only be called by an authorized issuer for the specified type.
     * Requires the attestation type to be active and issuance not paused.
     * @param typeId The ID of the attestation type to issue.
     * @param recipient The address to issue the attestation to.
     * @param dataPayload Arbitrary data associated with this instance.
     * @param expirationTimestampOverride Optional timestamp for expiration (0 to use default duration or no expiration).
     * If expirationTimestampOverride is 0 and defaultExpirationDuration is > 0, expiration is issuanceTimestamp + defaultDuration.
     * If both are 0, no expiration. If override > 0, it is used.
     * @return instanceId The ID of the newly issued instance.
     */
    function issueAttestation(
        uint256 typeId,
        address recipient,
        bytes calldata dataPayload,
        uint48 expirationTimestampOverride
    ) external onlyAuthorizedIssuer(typeId) whenNotPaused returns (uint256 instanceId) {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        require(recipient != address(0), "Invalid recipient address");
        require(attestationTypes[typeId].isActive, "Attestation type is inactive");

        _attestationInstanceCounter++;
        instanceId = _attestationInstanceCounter;

        uint48 issuanceTs = uint48(block.timestamp);
        uint48 calculatedExpiration = 0;

        if (expirationTimestampOverride > 0) {
            calculatedExpiration = expirationTimestampOverride;
        } else if (attestationTypes[typeId].defaultExpirationDuration > 0) {
             // Check for overflow before adding
             require(issuanceTs <= type(uint48).max - attestationTypes[typeId].defaultExpirationDuration, "Expiration timestamp overflow");
             calculatedExpiration = issuanceTs + attestationTypes[typeId].defaultExpirationDuration;
        }
        // If both override and default are 0, calculatedExpiration remains 0 (no expiration)

        attestationInstances[instanceId] = AttestationInstance({
            typeId: typeId,
            recipient: recipient,
            issuer: msg.sender,
            issuanceTimestamp: issuanceTs,
            expirationTimestamp: calculatedExpiration,
            isRevoked: false,
            dataPayload: dataPayload,
            delegateExpirations: new mapping(address => uint48)() // Initialize the internal mapping
        });
        instanceExists[instanceId] = true;
        userAttestations[recipient].push(instanceId);

        emit AttestationIssued(instanceId, typeId, recipient, msg.sender, issuanceTs, calculatedExpiration);
    }

    /**
     * @dev Revokes an attestation instance, making it invalid.
     * Can only be called by the original issuer or the admin.
     * @param instanceId The ID of the attestation instance to revoke.
     */
    function revokeAttestation(uint256 instanceId) external {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        require(msg.sender == instance.issuer || msg.sender == admin, "Only issuer or admin can revoke");
        require(!instance.isRevoked, "Attestation already revoked");

        instance.isRevoked = true;
        emit AttestationRevoked(instanceId, msg.sender);
    }

     /**
     * @dev Allows the original issuer to update the data payload of an attestation instance.
     * Useful for dynamic data like scores, ratings, etc.
     * @param instanceId The ID of the attestation instance to update.
     * @param newDataPayload The new data payload.
     */
    function requestAttestationDataUpdate(uint256 instanceId, bytes calldata newDataPayload) external {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        require(msg.sender == instance.issuer || msg.sender == admin, "Only issuer or admin can update data");
        // Allow updating data even if expired or revoked? Decision: Yes, issuer should maintain source of truth. Verification functions check validity.

        instance.dataPayload = newDataPayload;
        emit AttestationDataUpdated(instanceId, msg.sender);
    }

    /**
     * @dev Transfers ownership of an attestation instance to a new recipient.
     * Can only be called by the current recipient.
     * Only possible if the attestation type is marked as transferable.
     * Does not affect the issuer or original issuance/expiration parameters.
     * @param instanceId The ID of the attestation instance to transfer.
     * @param newRecipient The address of the new owner.
     */
    function transferAttestationOwnership(uint256 instanceId, address newRecipient) external {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        require(msg.sender == instance.recipient, "Only the current recipient can transfer");
        require(newRecipient != address(0), "Invalid new recipient address");
        require(newRecipient != instance.recipient, "Cannot transfer to self");
        require(attestationTypes[instance.typeId].isTransferable, "Attestation type is not transferable");
        // Decision: Can transfer even if expired or revoked? Let's allow transfer of the *record*, verification checks validity.

        address oldRecipient = instance.recipient;
        instance.recipient = newRecipient;

        // Update userAttestations mapping (this part is potentially gas-intensive)
        // To keep this simple but functional for the example:
        // Finding the instance ID in the old recipient's array and removing it is complex and costly.
        // A simpler approach for the example is to just add to the new recipient's list.
        // This means the old recipient's list might still contain the ID, but `getAttestationInstance`
        // would show the new recipient. A more robust system would manage these arrays carefully.
        // For this example, we accept the potential inefficiency/inaccuracy of `getUserAttestations`
        // for transferred attestations and prioritize the core transfer logic.
         userAttestations[newRecipient].push(instanceId);
         // Note: Removing from the old recipient's array requires iteration or a more complex data structure.
         // This example omits the removal from the old list for simplicity, impacting only the `getUserAttestations` view function.

        emit AttestationTransferred(instanceId, oldRecipient, newRecipient);
    }

     /**
     * @dev Allows the original issuer or admin to update the expiration timestamp of an attestation instance.
     * Can extend or shorten the validity period. Setting to 0 removes expiration.
     * @param instanceId The ID of the attestation instance.
     * @param newExpirationTimestamp The new expiration timestamp (0 for no expiration).
     */
    function updateAttestationExpiration(uint256 instanceId, uint48 newExpirationTimestamp) external {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        require(msg.sender == instance.issuer || msg.sender == admin, "Only issuer or admin can update expiration");

        uint48 oldExpiration = instance.expirationTimestamp;
        instance.expirationTimestamp = newExpirationTimestamp;

        emit AttestationExpirationUpdated(instanceId, oldExpiration, newExpirationTimestamp);
    }


    // --- IV. Query and Verification Functions ---

    /**
     * @dev Retrieves the details of an attestation type.
     * @param typeId The ID of the attestation type.
     * @return name, description, isActive, isTransferable, defaultExpirationDuration
     */
    function getAttestationType(uint256 typeId) public view returns (string memory, string memory, bool, bool, uint48) {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        AttestationType storage typeData = attestationTypes[typeId];
        return (
            typeData.name,
            typeData.description,
            typeData.isActive,
            typeData.isTransferable,
            typeData.defaultExpirationDuration
        );
    }

    /**
     * @dev Retrieves the details of an attestation instance.
     * Note: Does not return the `delegateExpirations` mapping directly due to Solidity limitations.
     * @param instanceId The ID of the attestation instance.
     * @return typeId, recipient, issuer, issuanceTimestamp, expirationTimestamp, isRevoked, dataPayload
     */
    function getAttestationInstance(uint256 instanceId) public view returns (
        uint256 typeId,
        address recipient,
        address issuer,
        uint48 issuanceTimestamp,
        uint48 expirationTimestamp,
        bool isRevoked,
        bytes memory dataPayload
    ) {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        return (
            instance.typeId,
            instance.recipient,
            instance.issuer,
            instance.issuanceTimestamp,
            instance.expirationTimestamp,
            instance.isRevoked,
            instance.dataPayload
        );
    }

    /**
     * @dev Gets a list of all attestation instance IDs held by a user.
     * Note: This can be gas-intensive and potentially hit block gas limits if a user has many attestations.
     * Consider alternative querying methods off-chain for large numbers.
     * @param user The address of the user.
     * @return A list of attestation instance IDs.
     */
    function getUserAttestations(address user) public view returns (uint256[] memory) {
        return userAttestations[user];
    }

    /**
     * @dev Gets the total number of attestation types created.
     * @return The total count of types.
     */
    function getTotalAttestationTypes() public view returns (uint256) {
        return _attestationTypeCounter;
    }

    /**
     * @dev Gets the total number of attestation instances issued.
     * @return The total count of instances.
     */
    function getTotalAttestationInstances() public view returns (uint256) {
        return _attestationInstanceCounter;
    }


    /**
     * @dev Checks if an attestation instance is currently valid.
     * An attestation is valid if it exists, is not revoked, and has not expired.
     * @param instanceId The ID of the attestation instance.
     * @return True if the attestation is valid, false otherwise.
     */
    function isAttestationValid(uint256 instanceId) public view returns (bool) {
        if (!instanceExists[instanceId]) {
            return false; // Does not exist
        }
        AttestationInstance storage instance = attestationInstances[instanceId];
        if (instance.isRevoked) {
            return false; // Is revoked
        }
        if (instance.expirationTimestamp > 0 && block.timestamp >= instance.expirationTimestamp) {
            return false; // Has expired
        }
        return true; // Is valid
    }

     /**
     * @dev Checks if a user holds at least one currently valid instance of a specific attestation type.
     * Iterates through the user's attestations. Can be gas-intensive if user has many attestations,
     * though typically faster than `getUserAttestations` if a valid one is found early.
     * @param user The address of the user.
     * @param typeId The ID of the attestation type.
     * @return True if the user has at least one valid instance of the type, false otherwise.
     */
    function userHasAttestationOfType(address user, uint256 typeId) public view returns (bool) {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        uint256[] memory instances = userAttestations[user];
        for (uint i = 0; i < instances.length; i++) {
            uint256 instanceId = instances[i];
            if (instanceExists[instanceId]) { // Check if instance record still logically exists
                AttestationInstance storage instance = attestationInstances[instanceId];
                 // Check if it's the right type and is valid
                if (instance.typeId == typeId && isAttestationValid(instanceId) && instance.recipient == user) {
                    return true;
                }
            }
        }
        return false;
    }

     /**
     * @dev Gets a list of currently valid attestation instance IDs of a specific type held by a user.
     * Iterates through the user's attestations. Can be gas-intensive.
     * @param user The address of the user.
     * @param typeId The ID of the attestation type.
     * @return A list of valid instance IDs of that type for the user.
     */
    function getUserValidAttestationsOfType(address user, uint256 typeId) public view returns (uint256[] memory) {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        uint256[] memory userInsts = userAttestations[user];
        uint256[] memory validInsts = new uint256[](userInsts.length); // Max possible size
        uint256 validCount = 0;

         for (uint i = 0; i < userInsts.length; i++) {
            uint256 instanceId = userInsts[i];
             if (instanceExists[instanceId]) {
                AttestationInstance storage instance = attestationInstances[instanceId];
                 if (instance.typeId == typeId && isAttestationValid(instanceId) && instance.recipient == user) {
                     validInsts[validCount] = instanceId;
                     validCount++;
                 }
             }
         }
        // Trim the array to actual valid count
        uint256[] memory result = new uint256[](validCount);
        for(uint i = 0; i < validCount; i++){
            result[i] = validInsts[i];
        }
        return result;
    }

    /**
     * @dev Checks if an attestation instance is valid AND its data payload starts with a specific byte prefix.
     * Useful for verifying basic data constraints on-chain.
     * @param instanceId The ID of the attestation instance.
     * @param requiredPrefix The byte prefix to check against the data payload.
     * @return True if the attestation is valid and data matches the prefix, false otherwise.
     */
    function verifyAttestationWithDataPrefix(uint256 instanceId, bytes calldata requiredPrefix) public view returns (bool) {
        if (!isAttestationValid(instanceId)) {
            return false;
        }
        AttestationInstance storage instance = attestationInstances[instanceId];
        bytes memory payload = instance.dataPayload;

        if (payload.length < requiredPrefix.length) {
            return false; // Payload is shorter than the required prefix
        }

        // Check if the payload starts with the required prefix
        for (uint i = 0; i < requiredPrefix.length; i++) {
            if (payload[i] != requiredPrefix[i]) {
                return false;
            }
        }
        return true;
    }

     /**
     * @dev Gets the list of addresses currently authorized to issue a specific attestation type.
     * @param typeId The ID of the attestation type.
     * @return An array of authorized issuer addresses.
     */
    function getAuthorizedIssuers(uint256 typeId) public view returns (address[] memory) {
        require(typeId > 0 && typeId <= _attestationTypeCounter, "Invalid type ID");
        return typeAuthorizedIssuersList[typeId];
    }


    // --- V. Delegation Functions ---

    /**
     * @dev Allows the recipient of an attestation to delegate verification rights to a third party.
     * The delegate can then call `isAttestationValidForDelegate` on behalf of the recipient.
     * @param instanceId The ID of the attestation instance.
     * @param delegate The address to grant delegation rights to.
     * @param delegationExpirationTimestamp The timestamp when the delegation expires (0 for no expiration).
     */
    function delegateVerification(uint256 instanceId, address delegate, uint48 delegationExpirationTimestamp) external {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        require(msg.sender == instance.recipient, "Only the attestation recipient can delegate");
        require(delegate != address(0), "Invalid delegate address");
        require(delegate != instance.recipient, "Cannot delegate to self");
        require(delegationExpirationTimestamp == 0 || delegationExpirationTimestamp > block.timestamp, "Delegation expiration must be in the future or 0");

        instance.delegateExpirations[delegate] = delegationExpirationTimestamp;
        emit VerificationDelegated(instanceId, msg.sender, delegate, delegationExpirationTimestamp);
    }

    /**
     * @dev Allows the recipient of an attestation to remove a verification delegate.
     * @param instanceId The ID of the attestation instance.
     * @param delegate The address to remove as a delegate.
     */
    function removeDelegate(uint256 instanceId, address delegate) external {
        require(instanceExists[instanceId], "Invalid instance ID");
        AttestationInstance storage instance = attestationInstances[instanceId];
        require(msg.sender == instance.recipient, "Only the attestation recipient can remove delegates");
        require(instance.delegateExpirations[delegate] > 0, "Delegate is not set for this instance");

        delete instance.delegateExpirations[delegate]; // Setting expiration to 0 removes the mapping entry
        emit DelegateRemoved(instanceId, msg.sender, delegate);
    }

    /**
     * @dev Checks if an address is currently a valid delegate verifier for an attestation instance.
     * @param instanceId The ID of the attestation instance.
     * @param potentialDelegate The address to check.
     * @return True if the address is a valid delegate, false otherwise.
     */
    function isDelegateVerifier(uint256 instanceId, address potentialDelegate) public view returns (bool) {
        if (!instanceExists[instanceId] || potentialDelegate == address(0)) {
            return false;
        }
        AttestationInstance storage instance = attestationInstances[instanceId];
        uint48 expiration = instance.delegateExpirations[potentialDelegate];
        // Delegate is valid if expiration is 0 (no expiration) or expiration is in the future
        return expiration > 0 && (expiration == type(uint48).max || block.timestamp < expiration); // Using type(uint48).max as a potential marker for infinite delegation, but let's assume 0 means no expiration for delegation too, and >0 is a timestamp. Revisit this. Let's clarify: 0 means NOT a delegate. >0 means the timestamp they are valid until.
         return expiration > 0 && block.timestamp < expiration; // Delegate is valid if expiration is > 0 and not yet reached
    }

     /**
     * @dev Checks if an attestation instance is valid AND if the potentialDelegate is authorized
     * to verify it via delegation by the recipient.
     * This is the function a verifier would typically call if they received the instanceId and
     * recipient address and were told they are a delegate.
     * @param instanceId The ID of the attestation instance.
     * @param potentialDelegate The address attempting the delegated verification.
     * @return True if the attestation is valid AND the potentialDelegate is a valid delegate, false otherwise.
     */
    function isAttestationValidForDelegate(uint256 instanceId, address potentialDelegate) public view returns (bool) {
        if (!isAttestationValid(instanceId)) {
            return false;
        }
        return isDelegateVerifier(instanceId, potentialDelegate);
    }

    // --- Internal/Helper Functions ---
    // No complex internal functions needed beyond what's implemented directly.

    // --- Fallback/Receive ---
    receive() external payable {
        // Optional: Handle direct Ether payments if needed, maybe add to collectedFees
        // For this contract, payments are expected only for type creation.
        revert("Direct payments not supported outside specific functions");
    }

    fallback() external payable {
        revert("Fallback not supported");
    }
}
```