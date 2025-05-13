Okay, here is a smart contract concept called `MetaMorphRegistry`. It's designed as a flexible, modular registry for entities (addresses) to manage dynamic "traits," verify off-chain claims, and interact with trusted modules. It incorporates concepts like time-based validity, delegation, verifiable claims, and modular logic association.

This contract attempts to be creative by combining multiple functionalities often found in separate systems (identity, reputation, claims, delegation, modular execution/interpretation) into a single, albeit simplified, registry structure. It avoids being a standard ERC-20/721/1155, a simple multi-sig, or a basic DAO governor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline and Function Summary ---
/*
Contract: MetaMorphRegistry
Purpose: A flexible registry for managing entities (addresses) and their dynamic, time-sensitive traits, verifiable claims, and interactions with trusted modules. It aims to provide a base layer for decentralized identity, reputation, or verifiable status representation.

Core Concepts:
1. Entities: Registered addresses that can hold traits and claims.
2. Traits: Dynamic key-value pairs associated with an entity, with a validity period and issuer. Can be delegated for management.
3. Claims: Off-chain signed attestations about an entity, verifiable on-chain via signature and issuer.
4. Modules: Trusted external contracts that can be associated with trait types to provide custom logic (validation, scoring, side effects).
5. Access Control: Role-based access for administrative functions.
6. Time-Based Validity: Traits and claims can expire.
7. Delegation: Entities can delegate specific trait management rights.
8. Pausable: Emergency mechanism.

State Variables:
- _entities: Mapping to track registered entities.
- _traits: Nested mapping for storing traits per entity (entityAddress -> traitName -> Trait struct).
- _traitDelegates: Nested mapping for trait management delegation (entityAddress -> traitName -> delegateAddress).
- _claims: Nested mapping for verifiable claims (entityAddress -> claimHash -> Claim struct).
- _registeredModules: Mapping to track trusted module addresses.
- _traitModuleAssociations: Mapping to link trait names to module addresses.
- ADMIN_ROLE, MODULE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE: Access control roles.

Structs:
- Trait: Represents a dynamic property of an entity (value, validityEnd, issuer, addedTimestamp).
- Claim: Represents a verifiable off-chain attestation (issuer, claimHash, signature, validityEnd, addedTimestamp).

Events:
- EntityRegistered, EntityUnregistered
- TraitAdded, TraitUpdated, TraitRemoved, TraitManagementDelegated, TraitManagementRevoked
- ClaimAdded, ClaimRevoked
- ModuleRegistered, ModuleUnregistered
- ModuleAssociatedWithTrait, ModuleDissociatedFromTrait
- Paused, Unpaused
- EntityScoreCalculated (placeholder event)

Functions (Total: 30+):

Entity Management:
1. registerEntity(address entityAddress): Registers an address as an entity.
2. unregisterEntity(address entityAddress): Unregisters an entity and clears its data (can be restricted).
3. isEntityRegistered(address entityAddress): Checks if an address is a registered entity.
4. getRegisteredEntitiesCount(): Returns the total number of registered entities (uses a helper mapping or simply relies on `_entities` which requires iteration - note: iteration is not efficient on-chain, this is a simplified count). (Removed for gas efficiency, rely on events/off-chain indexer).
5. getEntityTraitsList(address entityAddress): Retrieves the list of trait names for an entity. (Requires iterating mapping keys - removed for gas efficiency, rely on events/off-chain indexer).

Trait Management:
6. addTrait(address entityAddress, string calldata traitName, bytes calldata value, uint64 validityEnd): Adds a new trait to an entity. Requires entity ownership or trait delegation.
7. updateTrait(address entityAddress, string calldata traitName, bytes calldata newValue, uint64 newValidityEnd): Updates an existing trait's value and validity. Requires ownership or delegation.
8. removeTrait(address entityAddress, string calldata traitName): Removes a trait from an entity. Requires ownership or delegation.
9. getTrait(address entityAddress, string caldata traitName): Retrieves a specific trait's details.
10. isValidTrait(address entityAddress, string calldata traitName): Checks if a trait exists and is currently valid based on `validityEnd`.
11. delegateTraitManagement(address entityAddress, string calldata traitName, address delegate): Allows `delegate` to manage `traitName` for `entityAddress`. Requires ownership.
12. revokeTraitManagementDelegation(address entityAddress, string calldata traitName): Revokes delegation for a trait. Requires ownership or current delegate status.
13. getTraitDelegate(address entityAddress, string calldata traitName): Gets the current delegate for a trait.
14. addVerifiableClaim(address entityAddress, bytes32 claimHash, bytes calldata signature, uint64 validityEnd): Adds a verifiable claim. The signature must be valid for `claimHash` signed by a pre-approved claim `issuer`. (Simplified: issuer is *caller* for now, advanced version would verify against *any* issuer). *Update*: Let's make the issuer explicit and verified.
15. getVerifiableClaim(address entityAddress, bytes32 claimHash): Retrieves a verifiable claim's details.
16. revokeVerifiableClaim(address entityAddress, bytes32 claimHash): Removes a verifiable claim. Requires entity ownership or claim issuer status.
17. isValidClaim(address entityAddress, bytes32 claimHash): Checks if a claim exists and is currently valid.

Module Management:
18. registerModule(address moduleAddress): Registers a contract address as a trusted module. Requires MODULE_MANAGER_ROLE.
19. unregisterModule(address moduleAddress): Unregisters a module. Requires MODULE_MANAGER_ROLE.
20. isModuleRegistered(address moduleAddress): Checks if an address is a registered module.
21. associateModuleWithTrait(string calldata traitName, address moduleAddress): Links a registered module to a specific trait name for custom logic processing. Requires MODULE_MANAGER_ROLE.
22. dissociateModuleFromTrait(string calldata traitName): Removes a module association from a trait. Requires MODULE_MANAGER_ROLE.
23. getModuleForTrait(string calldata traitName): Gets the module associated with a trait name.

Access Control & Utility:
24. grantRole(bytes32 role, address account): Grants a role (from AccessControl). Requires admin role for that role.
25. revokeRole(bytes32 role, address account): Revokes a role (from AccessControl). Requires admin role for that role.
26. renounceRole(bytes32 role): User renounces their own role.
27. pause(): Pauses contract functionality. Requires PAUSER_ROLE (or ADMIN_ROLE if PAUSER isn't defined). Let's use ADMIN_ROLE.
28. unpause(): Unpauses contract functionality. Requires ADMIN_ROLE.
29. batchAddTraits(address entityAddress, string[] calldata traitNames, bytes[] calldata values, uint64[] calldata validityEnds): Adds multiple traits in a single transaction. Requires ownership or relevant delegation.
30. batchRemoveTraits(address entityAddress, string[] calldata traitNames): Removes multiple traits in a single transaction. Requires ownership or relevant delegation.
31. calculateEntityScore(address entityAddress): A placeholder function demonstrating how derived values *could* be calculated based on traits and modules. (Simple logic implemented: counts valid traits, weighted by trait type). *Note: Complex scoring logic would likely be externalized or involve module calls.*
32. verifyClaimSignature(bytes32 claimHash, bytes calldata signature, address issuer): Pure helper function to verify ECDSA signature.
*/

contract MetaMorphRegistry is AccessControl, Pausable {

    // --- Access Control Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODULE_MANAGER_ROLE = keccak256("MODULE_MANAGER_ROLE");

    // --- Structs ---
    struct Trait {
        bytes value;
        uint64 validityEnd; // Unix timestamp
        address issuer; // Address that added/updated the trait
        uint64 addedTimestamp; // Timestamp when added
    }

    struct Claim {
        address issuer; // Address that signed the claim
        bytes32 claimHash; // Hash of the off-chain data being claimed
        bytes signature; // Signature of the claimHash by the issuer
        uint64 validityEnd; // Unix timestamp for claim validity
        uint64 addedTimestamp; // Timestamp when added
    }

    // --- State Variables ---
    mapping(address => bool) private _entities;
    mapping(address => mapping(string => Trait)) private _traits;
    mapping(address => mapping(string => address)) private _traitDelegates; // entityAddress => traitName => delegateAddress
    mapping(address => mapping(bytes32 => Claim)) private _claims; // entityAddress => claimHash => Claim struct
    mapping(address => bool) private _registeredModules;
    mapping(string => address) private _traitModuleAssociations; // traitName => moduleAddress

    // --- Events ---
    event EntityRegistered(address indexed entityAddress, address indexed registeredBy, uint64 timestamp);
    event EntityUnregistered(address indexed entityAddress, address indexed unregisteredBy, uint64 timestamp);

    event TraitAdded(address indexed entityAddress, string traitName, address indexed issuer, uint64 validityEnd, uint64 timestamp);
    event TraitUpdated(address indexed entityAddress, string traitName, address indexed updater, uint64 newValidityEnd, uint64 timestamp);
    event TraitRemoved(address indexed entityAddress, string traitName, address indexed removedBy, uint64 timestamp);
    event TraitManagementDelegated(address indexed entityAddress, string traitName, address indexed delegate, address indexed delegatedBy, uint64 timestamp);
    event TraitManagementRevoked(address indexed entityAddress, string traitName, address indexed delegate, address indexed revokedBy, uint66 timestamp);

    event ClaimAdded(address indexed entityAddress, bytes32 indexed claimHash, address indexed issuer, uint64 validityEnd, uint64 timestamp);
    event ClaimRevoked(address indexed entityAddress, bytes32 indexed claimHash, address indexed revokedBy, uint64 timestamp);

    event ModuleRegistered(address indexed moduleAddress, address indexed registeredBy, uint64 timestamp);
    event ModuleUnregistered(address indexed moduleAddress, address indexed unregisteredBy, uint64 timestamp);
    event ModuleAssociatedWithTrait(string indexed traitName, address indexed moduleAddress, address indexed setBy, uint64 timestamp);
    event ModuleDissociatedFromTrait(string indexed traitName, address indexed removedBy, uint64 timestamp);

    event EntityScoreCalculated(address indexed entityAddress, uint256 score, uint64 timestamp);

    // --- Constructor ---
    constructor(address defaultAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin); // Admin can manage entities and pause
        _grantRole(MODULE_MANAGER_ROLE, defaultAdmin); // Module managers can register/unregister modules and associations
    }

    // --- Modifiers ---
    modifier onlyEntityOrDelegate(address entityAddress, string calldata traitName) {
        require(msg.sender == entityAddress || _traitDelegates[entityAddress][traitName] == msg.sender, "MetaMorphRegistry: Not entity owner or delegate");
        _;
    }

    // --- Entity Management ---

    /**
     * @notice Registers an address as an entity in the registry.
     * @param entityAddress The address to register.
     */
    function registerEntity(address entityAddress) public whenNotPaused {
        require(!_entities[entityAddress], "MetaMorphRegistry: Entity already registered");
        _entities[entityAddress] = true;
        emit EntityRegistered(entityAddress, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Unregisters an entity and clears its associated data (traits, claims, delegations).
     * @param entityAddress The address to unregister.
     * @dev This is a destructive action. May require ADMIN_ROLE or self-service depending on design.
     *      Implemented as self-service or ADMIN_ROLE.
     */
    function unregisterEntity(address entityAddress) public whenNotPaused {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        require(msg.sender == entityAddress || hasRole(ADMIN_ROLE, msg.sender), "MetaMorphRegistry: Not authorized to unregister");

        delete _entities[entityAddress];

        // Clear traits, claims, and delegations for this entity
        // Note: Iterating mappings is not possible on-chain. This cleanup
        // must rely on external systems tracking state via events,
        // or a more complex storage structure (e.g., enumerable mappings).
        // For this example, we emit an event indicating data is cleared,
        // implying off-chain cleanup or logical deletion.
        // A full on-chain clear for traits/claims would require knowing their keys,
        // which is impractical without enumerable structures.
        // delete _traits[entityAddress]; // Cannot delete nested mapping like this fully
        // delete _traitDelegates[entityAddress];
        // delete _claims[entityAddress];

        emit EntityUnregistered(entityAddress, msg.sender, uint64(block.timestamp));
        // Emit events indicating related data is now invalid/cleared
        // (Specific trait/claim deletion events are not practical here without keys)
    }

    /**
     * @notice Checks if an address is a registered entity.
     * @param entityAddress The address to check.
     * @return bool True if the entity is registered, false otherwise.
     */
    function isEntityRegistered(address entityAddress) public view returns (bool) {
        return _entities[entityAddress];
    }

    // getRegisteredEntitiesCount() - See comment in Summary/Outline. Avoided for gas efficiency.
    // getEntityTraitsList() - See comment in Summary/Outline. Avoided for gas efficiency.

    // --- Trait Management ---

    /**
     * @notice Adds or updates a trait for an entity.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @param value The value of the trait (arbitrary bytes).
     * @param validityEnd The Unix timestamp when the trait expires (0 for no expiration).
     */
    function addTrait(
        address entityAddress,
        string calldata traitName,
        bytes calldata value,
        uint64 validityEnd
    ) public whenNotPaused onlyEntityOrDelegate(entityAddress, traitName) {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        require(bytes(traitName).length > 0, "MetaMorphRegistry: Trait name cannot be empty");

        bool exists = false;
        if (_traits[entityAddress][traitName].addedTimestamp > 0) {
             exists = true; // Simple check if struct was initialized
        }

        _traits[entityAddress][traitName] = Trait({
            value: value,
            validityEnd: validityEnd,
            issuer: msg.sender,
            addedTimestamp: exists ? _traits[entityAddress][traitName].addedTimestamp : uint64(block.timestamp)
        });

        if (exists) {
            emit TraitUpdated(entityAddress, traitName, msg.sender, validityEnd, uint64(block.timestamp));
        } else {
            emit TraitAdded(entityAddress, traitName, msg.sender, validityEnd, uint64(block.timestamp));
        }

        // Optional: Trigger module logic if associated with this trait
        address moduleAddress = _traitModuleAssociations[traitName];
        if (moduleAddress != address(0)) {
            // Interaction with module - potentially dangerous depending on module
            // Example: Call a specific function on the module
            // bytes memory moduleCallData = abi.encodeWithSignature("onTraitUpdated(address,string,bytes)", entityAddress, traitName, value);
            // (bool success, ) = moduleAddress.call(moduleCallData);
            // require(success, "MetaMorphRegistry: Module call failed");
            // ^ Commented out for safety in this example, but shows the concept
        }
    }

    /**
     * @notice Updates the value and validity of an existing trait.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @param newValue The new value of the trait.
     * @param newValidityEnd The new Unix timestamp when the trait expires.
     */
    function updateTrait(
        address entityAddress,
        string calldata traitName,
        bytes calldata newValue,
        uint64 newValidityEnd
    ) public whenNotPaused onlyEntityOrDelegate(entityAddress, traitName) {
         require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
         require(_traits[entityAddress][traitName].addedTimestamp > 0, "MetaMorphRegistry: Trait does not exist"); // Check if trait was added

         _traits[entityAddress][traitName].value = newValue;
         _traits[entityAddress][traitName].validityEnd = newValidityEnd;
         _traits[entityAddress][traitName].issuer = msg.sender; // Updater becomes new issuer/last modifier

         emit TraitUpdated(entityAddress, traitName, msg.sender, newValidityEnd, uint64(block.timestamp));

         // Optional: Trigger module logic
         address moduleAddress = _traitModuleAssociations[traitName];
         if (moduleAddress != address(0)) {
             // See comment in addTrait about module interaction
         }
    }


    /**
     * @notice Removes a trait from an entity.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait to remove.
     */
    function removeTrait(address entityAddress, string calldata traitName) public whenNotPaused onlyEntityOrDelegate(entityAddress, traitName) {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        require(_traits[entityAddress][traitName].addedTimestamp > 0, "MetaMorphRegistry: Trait does not exist");

        delete _traits[entityAddress][traitName];
        // Also revoke any delegation for this trait specifically
        delete _traitDelegates[entityAddress][traitName];

        emit TraitRemoved(entityAddress, traitName, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Gets the details of a specific trait for an entity.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @return Trait The trait struct. Returns zeroed struct if not found.
     */
    function getTrait(address entityAddress, string calldata traitName) public view returns (Trait memory) {
        // No require for entity registered, allows checking for traits on non-entities if needed.
        return _traits[entityAddress][traitName];
    }

    /**
     * @notice Checks if a trait exists for an entity and is currently valid.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @return bool True if the trait exists and is valid, false otherwise.
     */
    function isValidTrait(address entityAddress, string calldata traitName) public view returns (bool) {
        Trait memory trait = _traits[entityAddress][traitName];
        // Check if trait exists (addedTimestamp > 0 implies it was set) and is not expired (or validityEnd is 0).
        return trait.addedTimestamp > 0 && (trait.validityEnd == 0 || trait.validityEnd > block.timestamp);
    }

    /**
     * @notice Delegates the management rights of a specific trait for an entity to another address.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @param delegate The address to delegate management rights to.
     * @dev Only the entity itself can delegate its trait management rights.
     */
    function delegateTraitManagement(address entityAddress, string calldata traitName, address delegate) public whenNotPaused {
        require(msg.sender == entityAddress, "MetaMorphRegistry: Only entity can delegate");
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        // Does NOT require trait to exist to delegate management *of* it. Delegation can be pre-emptive.

        _traitDelegates[entityAddress][traitName] = delegate;
        emit TraitManagementDelegated(entityAddress, traitName, delegate, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Revokes the delegation of a specific trait's management rights.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @dev Can be called by the entity owner or the current delegate.
     */
    function revokeTraitManagementDelegation(address entityAddress, string calldata traitName) public whenNotPaused {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        address currentDelegate = _traitDelegates[entityAddress][traitName];
        require(currentDelegate != address(0), "MetaMorphRegistry: No delegation exists for this trait");
        require(msg.sender == entityAddress || msg.sender == currentDelegate, "MetaMorphRegistry: Not authorized to revoke delegation");

        delete _traitDelegates[entityAddress][traitName];
        emit TraitManagementRevoked(entityAddress, traitName, currentDelegate, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Gets the current delegate for a specific trait of an entity.
     * @param entityAddress The entity's address.
     * @param traitName The name of the trait.
     * @return address The delegate's address, or address(0) if no delegation exists.
     */
    function getTraitDelegate(address entityAddress, string calldata traitName) public view returns (address) {
        return _traitDelegates[entityAddress][traitName];
    }

    // --- Verifiable Claim Management ---

    /**
     * @notice Adds a verifiable claim about an entity.
     * @param entityAddress The entity the claim is about.
     * @param claimHash The keccak256 hash of the off-chain claim data (e.g., JSON string of the claim).
     * @param signature The ECDSA signature of the claimHash by the issuer.
     * @param validityEnd The Unix timestamp when the claim expires.
     * @dev The `msg.sender` is recorded as the address that *added* the claim to the registry,
     *      but the signature must verify against the declared `issuer` address.
     *      A more robust version would require a list of trusted claim issuer addresses.
     *      Here, we derive the issuer from the signature and verify it matches an expected issuer address (if any).
     *      For simplicity, let's assume the claimHash is crafted *off-chain* to bind to the `entityAddress`
     *      and potentially the contract address/chain ID to prevent replay.
     *      E.g., `claimHash = keccak256(abi.encodePacked(contractAddress, chainId, entityAddress, yourClaimDataHash))`.
     *      The `issuer` is derived from the signature of this `claimHash`.
     */
    function addVerifiableClaim(
        address entityAddress,
        bytes32 claimHash,
        bytes calldata signature,
        uint64 validityEnd
    ) public whenNotPaused {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        require(claimHash != bytes32(0), "MetaMorphRegistry: Claim hash cannot be zero");
        require(signature.length > 0, "MetaMorphRegistry: Signature cannot be empty");

        // Verify the signature and recover the issuer address
        address issuer = ECDSA.recover(claimHash, signature);
        require(issuer != address(0), "MetaMorphRegistry: Invalid signature");

        // Optional: Add a check here if the 'issuer' is from a list of trusted claim issuers
        // For now, any address that can sign the claimHash is considered the issuer.

        _claims[entityAddress][claimHash] = Claim({
            issuer: issuer,
            claimHash: claimHash,
            signature: signature,
            validityEnd: validityEnd,
            addedTimestamp: uint64(block.timestamp)
        });

        emit ClaimAdded(entityAddress, claimHash, issuer, validityEnd, uint64(block.timestamp));
    }

     /**
     * @notice Gets the details of a specific verifiable claim for an entity.
     * @param entityAddress The entity's address.
     * @param claimHash The hash of the claim data.
     * @return Claim The claim struct. Returns zeroed struct if not found.
     */
    function getVerifiableClaim(address entityAddress, bytes32 claimHash) public view returns (Claim memory) {
         // No require for entity registered
        return _claims[entityAddress][claimHash];
    }

    /**
     * @notice Revokes a verifiable claim for an entity.
     * @param entityAddress The entity the claim is about.
     * @param claimHash The hash of the claim data to revoke.
     * @dev Can be called by the entity owner or the original claim issuer.
     */
    function revokeVerifiableClaim(address entityAddress, bytes32 claimHash) public whenNotPaused {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        Claim storage claim = _claims[entityAddress][claimHash];
        require(claim.issuer != address(0), "MetaMorphRegistry: Claim does not exist"); // Check if claim exists

        require(msg.sender == entityAddress || msg.sender == claim.issuer || hasRole(ADMIN_ROLE, msg.sender),
                "MetaMorphRegistry: Not authorized to revoke claim");

        delete _claims[entityAddress][claimHash];
        emit ClaimRevoked(entityAddress, claimHash, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Checks if a verifiable claim exists for an entity and is currently valid.
     * @param entityAddress The entity's address.
     * @param claimHash The hash of the claim data.
     * @return bool True if the claim exists and is valid, false otherwise.
     */
    function isValidClaim(address entityAddress, bytes32 claimHash) public view returns (bool) {
        Claim memory claim = _claims[entityAddress][claimHash];
        // Check if claim exists (issuer != address(0) implies it was set) and is not expired (or validityEnd is 0).
        return claim.issuer != address(0) && (claim.validityEnd == 0 || claim.validityEnd > block.timestamp);
    }

    /**
     * @notice Helper function to verify an ECDSA signature against a hash and an expected signer.
     * @param claimHash The hash that was signed.
     * @param signature The signature bytes.
     * @param issuer The expected address that signed the hash.
     * @return bool True if the signature is valid and matches the issuer, false otherwise.
     */
    function verifyClaimSignature(bytes32 claimHash, bytes calldata signature, address issuer) public pure returns (bool) {
         address recoveredIssuer = ECDSA.recover(claimHash, signature);
         return recoveredIssuer == issuer;
    }

    // --- Module Management ---

    /**
     * @notice Registers a contract address as a trusted module.
     * @param moduleAddress The address of the module contract.
     * @dev Only accounts with the MODULE_MANAGER_ROLE can register modules.
     */
    function registerModule(address moduleAddress) public whenNotPaused onlyRole(MODULE_MANAGER_ROLE) {
        require(moduleAddress != address(0), "MetaMorphRegistry: Module address cannot be zero");
        require(!_registeredModules[moduleAddress], "MetaMorphRegistry: Module already registered");
        // Optional: Add check here if moduleAddress is actually a contract (using Address.isContract)
        require(Address.isContract(moduleAddress), "MetaMorphRegistry: Address must be a contract");

        _registeredModules[moduleAddress] = true;
        emit ModuleRegistered(moduleAddress, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Unregisters a trusted module.
     * @param moduleAddress The address of the module contract.
     * @dev Unregistering a module does NOT automatically remove its trait associations.
     *      Those must be removed separately.
     *      Only accounts with the MODULE_MANAGER_ROLE can unregister modules.
     */
    function unregisterModule(address moduleAddress) public whenNotPaused onlyRole(MODULE_MANAGER_ROLE) {
        require(_registeredModules[moduleAddress], "MetaMorphRegistry: Module not registered");

        delete _registeredModules[moduleAddress];
        // Note: Does not clear trait associations automatically for gas efficiency.
        // Managers should call dissociateModuleFromTrait explicitly.
        emit ModuleUnregistered(moduleAddress, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice Checks if an address is a registered module.
     * @param moduleAddress The address to check.
     * @return bool True if the module is registered, false otherwise.
     */
    function isModuleRegistered(address moduleAddress) public view returns (bool) {
        return _registeredModules[moduleAddress];
    }

    /**
     * @notice Associates a registered module with a specific trait name.
     * @param traitName The name of the trait.
     * @param moduleAddress The address of the module to associate. Must be registered.
     * @dev Only accounts with the MODULE_MANAGER_ROLE can set associations.
     */
    function associateModuleWithTrait(string calldata traitName, address moduleAddress) public whenNotPaused onlyRole(MODULE_MANAGER_ROLE) {
        require(bytes(traitName).length > 0, "MetaMorphRegistry: Trait name cannot be empty");
        require(_registeredModules[moduleAddress], "MetaMorphRegistry: Module must be registered");
        // Allow associating address(0) to effectively remove an association without unregistering the module
        require(moduleAddress == address(0) || _registeredModules[moduleAddress], "MetaMorphRegistry: Module must be registered or address(0)");


        address currentModule = _traitModuleAssociations[traitName];
        if (currentModule != moduleAddress) {
            _traitModuleAssociations[traitName] = moduleAddress;
            emit ModuleAssociatedWithTrait(traitName, moduleAddress, msg.sender, uint64(block.timestamp));
        }
    }

    /**
     * @notice Removes the module association for a specific trait name.
     * @param traitName The name of the trait.
     * @dev Only accounts with the MODULE_MANAGER_ROLE can remove associations.
     */
    function dissociateModuleFromTrait(string calldata traitName) public whenNotPaused onlyRole(MODULE_MANAGER_ROLE) {
         require(bytes(traitName).length > 0, "MetaMorphRegistry: Trait name cannot be empty");
         address currentModule = _traitModuleAssociations[traitName];
         if (currentModule != address(0)) {
             delete _traitModuleAssociations[traitName];
             emit ModuleDissociatedFromTrait(traitName, msg.sender, uint64(block.timestamp));
         }
    }

    /**
     * @notice Gets the module address associated with a specific trait name.
     * @param traitName The name of the trait.
     * @return address The module address, or address(0) if no association exists.
     */
    function getModuleForTrait(string calldata traitName) public view returns (address) {
        return _traitModuleAssociations[traitName];
    }

    // --- Batch Operations ---

    /**
     * @notice Adds multiple traits for an entity in a single transaction.
     * @param entityAddress The entity's address.
     * @param traitNames Array of trait names.
     * @param values Array of trait values (must match names length).
     * @param validityEnds Array of validity end timestamps (must match names length).
     * @dev Caller must have rights (owner or delegate) for EACH trait name in the batch.
     *      If any trait fails the permission check, the whole transaction reverts.
     *      Arrays must be of equal length.
     */
    function batchAddTraits(
        address entityAddress,
        string[] calldata traitNames,
        bytes[] calldata values,
        uint64[] calldata validityEnds
    ) public whenNotPaused {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
        require(traitNames.length == values.length && values.length == validityEnds.length, "MetaMorphRegistry: Array length mismatch");
        require(traitNames.length > 0, "MetaMorphRegistry: Batch must not be empty");

        for (uint i = 0; i < traitNames.length; i++) {
            // Check permissions for each trait
            require(msg.sender == entityAddress || _traitDelegates[entityAddress][traitNames[i]] == msg.sender,
                    string(abi.encodePacked("MetaMorphRegistry: Not authorized for trait: ", traitNames[i])));

            bool exists = false;
            if (_traits[entityAddress][traitNames[i]].addedTimestamp > 0) {
                 exists = true;
            }

             _traits[entityAddress][traitNames[i]] = Trait({
                 value: values[i],
                 validityEnd: validityEnds[i],
                 issuer: msg.sender,
                 addedTimestamp: exists ? _traits[entityAddress][traitNames[i]].addedTimestamp : uint64(block.timestamp)
             });

             if (exists) {
                 emit TraitUpdated(entityAddress, traitNames[i], msg.sender, validityEnds[i], uint64(block.timestamp));
             } else {
                 emit TraitAdded(entityAddress, traitNames[i], msg.sender, validityEnds[i], uint64(block.timestamp));
             }
             // Note: Module interaction for each trait is omitted here for gas/complexity
        }
    }

     /**
     * @notice Removes multiple traits for an entity in a single transaction.
     * @param entityAddress The entity's address.
     * @param traitNames Array of trait names to remove.
     * @dev Caller must have rights (owner or delegate) for EACH trait name in the batch.
     *      If any trait fails the permission check or doesn't exist, the whole transaction reverts.
     */
    function batchRemoveTraits(address entityAddress, string[] calldata traitNames) public whenNotPaused {
         require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");
         require(traitNames.length > 0, "MetaMorphRegistry: Batch must not be empty");

         for (uint i = 0; i < traitNames.length; i++) {
            // Check permissions for each trait
            require(msg.sender == entityAddress || _traitDelegates[entityAddress][traitNames[i]] == msg.sender,
                    string(abi.encodePacked("MetaMorphRegistry: Not authorized for trait: ", traitNames[i])));
             require(_traits[entityAddress][traitNames[i]].addedTimestamp > 0, string(abi.encodePacked("MetaMorphRegistry: Trait does not exist: ", traitNames[i])));


             delete _traits[entityAddress][traitNames[i]];
             delete _traitDelegates[entityAddress][traitNames[i]]; // Also clear delegation for the removed trait
             emit TraitRemoved(entityAddress, traitNames[i], msg.sender, uint64(block.timestamp));
         }
    }

    // --- Utility / Derived Concepts ---

    /**
     * @notice Calculates a simplified score for an entity based on its valid traits.
     * @param entityAddress The entity's address.
     * @return uint256 A score based on valid traits.
     * @dev This is a *placeholder* for a more complex scoring mechanism.
     *      A real-world scenario might involve:
     *      - Specific trait values contributing different points.
     *      - Trait validity period impacting the score (decay).
     *      - Calling associated modules to get scoring input.
     *      - Reading verifiable claims.
     *      Iteration over all traits/claims is gas-prohibitive for entities with many items.
     *      This example only counts valid traits found *if you knew their names*.
     *      To make it work without knowing all trait names, external processing or
     *      a different storage pattern (like enumerable traits/claims) is needed.
     *      For demonstration, let's iterate over a hypothetical *fixed list* of trait types
     *      and add points if they are valid.
     */
    function calculateEntityScore(address entityAddress) public view returns (uint256) {
        require(_entities[entityAddress], "MetaMorphRegistry: Entity not registered");

        uint256 score = 0;
        uint64 currentTime = uint64(block.timestamp);

        // --- Simple Placeholder Scoring Logic ---
        // Iterate over a hypothetical list of known "important" traits.
        // In reality, you'd need to know the trait names beforehand or
        // use events to track which traits exist.
        string[] memory importantTraits = new string[](3);
        importantTraits[0] = "has_verified_email";
        importantTraits[1] = "reputation_score"; // If this trait exists, maybe add its value? (Requires parsing bytes)
        importantTraits[2] = "kyc_verified";

        for (uint i = 0; i < importantTraits.length; i++) {
            Trait storage trait = _traits[entityAddress][importantTraits[i]];
            // Check if trait exists and is valid
            if (trait.addedTimestamp > 0 && (trait.validityEnd == 0 || trait.validityEnd > currentTime)) {
                // Simple point system: +1 for each valid important trait
                 score += 1;

                 // Example: If trait is "reputation_score", try to add its value (assuming bytes is a uint representation)
                 if (keccak256(bytes(importantTraits[i])) == keccak256(bytes("reputation_score")) && trait.value.length >= 32) {
                     // Attempt to decode uint256 from bytes (assumes big-endian)
                     // This is simplified and unsafe without careful encoding/decoding
                     // bytes32 valueBytes32 = bytes32(trait.value[0..32]);
                     // uint256 reputationValue = uint256(valueBytes32);
                     // score += reputationValue; // Add reputation value to score
                     // More safely, you'd encode the score as a specific type.
                     // For this example, we'll just add a fixed bonus.
                     score += 10; // Bonus for having a reputation score trait
                 }
            }
        }

        // Example: Add points for valid claims
        // Cannot iterate claims mapping either. Placeholder logic: if a specific claim exists...
        bytes32 hypotheticalClaimHash = keccak256("HypotheticalImportantClaim"); // Off-chain derived hash
        Claim storage claim = _claims[entityAddress][hypotheticalClaimHash];
        if (claim.issuer != address(0) && (claim.validityEnd == 0 || claim.validityEnd > currentTime)) {
             score += 5; // Bonus for having a specific important claim
        }


        // Emitting an event here is more for logging that calculation happened,
        // the score is returned directly by the view function.
        emit EntityScoreCalculated(entityAddress, score, uint64(block.timestamp)); // Event useful for off-chain indexing

        return score;
    }

    // --- Pausable Functionality ---

    /**
     * @notice Pauses the contract. Prevents most state-changing operations.
     * @dev Only accounts with the ADMIN_ROLE can pause.
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract. Re-enables state-changing operations.
     * @dev Only accounts with the ADMIN_ROLE can unpause.
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // --- Overrides for AccessControl ---
    // Allow the default admin to grant roles initially
    // You might want more complex role management in a production setting.
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {} // Example integration point for upgradeable proxies

}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Traits:** Instead of fixed fields, entities have a mapping of `string` trait names to arbitrary `bytes` values. This allows storing diverse types of data (encoded appropriately) and adding new "types" of information without contract upgrades.
2.  **Time-Based Validity:** Traits and claims have a `validityEnd` timestamp, introducing a temporal dimension. Data in the registry isn't static; it can expire, requiring renewal or recalculation (like the scoring).
3.  **Trait Management Delegation:** Entities can delegate control over *specific* traits to other addresses. This is useful for scenarios like assigning an admin to manage a "status" trait, or letting a service provider update a "subscription" trait.
4.  **Verifiable Claims:** The contract allows recording *verifiable attestations* about an entity. These claims are signed off-chain by an issuer and stored on-chain. This provides a decentralized way to link off-chain reputation or identity proofs to an on-chain entity, while still allowing verification of the source (the issuer's signature). The `claimHash` structure suggests the claim data itself is off-chain, saving gas.
5.  **Modular Logic Association:** The `_traitModuleAssociations` mapping allows linking a `traitName` to a registered module contract. While the example contract doesn't *automatically* call modules on trait changes (to avoid Reentrancy and gas issues), the structure is there. A more advanced version could use delegatecalls to modules for validation, derived calculations, or side effects triggered by trait changes. The `calculateEntityScore` function demonstrates a point where module logic *could* be consulted.
6.  **Role-Based Access Control:** Uses OpenZeppelin's `AccessControl` for granular permissions (ADMIN, MODULE_MANAGER) instead of a single owner, which is more flexible and standard for non-trivial contracts.
7.  **Batch Operations:** Includes functions (`batchAddTraits`, `batchRemoveTraits`) to perform multiple trait operations in a single transaction, improving gas efficiency for users managing several traits.

**Limitations and Considerations (as with many on-chain data structures):**

*   **Mapping Iteration:** Solidity mappings cannot be iterated. Functions like `getEntityTraitsList` or retrieving *all* entities/traits for a user require external indexing (listening to events) or using more complex, gas-intensive enumerable data structures (like OpenZeppelin's `EnumerableSet`). The current version relies on external indexers for full listing capabilities.
*   **Gas Costs:** Storing and updating data on-chain is costly. Arbitrary `bytes` values for traits add flexibility but can increase gas costs if the data is large.
*   **Module Security:** If module contracts were actively called by the registry, their security would be paramount to avoid vulnerabilities affecting the registry itself. The example deliberately avoids active calls for simplicity and safety.
*   **Claim Data:** The contract only stores the *hash* and *signature* of a claim. The actual claim data must be stored and made available off-chain.
*   **Scoring Logic:** The `calculateEntityScore` is a basic illustration. Real-world scoring would be significantly more complex, likely requiring external computation or more sophisticated on-chain logic that considers various factors including trait values, claim verification results, module outputs, and potentially time-based decay algorithms.

This contract structure provides a foundation for building systems that manage dynamic, verifiable identity attributes and interact with specialized logic modules, going beyond simple token or fixed-data patterns.