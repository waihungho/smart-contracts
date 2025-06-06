Okay, let's design a creative and somewhat advanced smart contract concept that isn't a direct copy of standard open-source patterns like ERC20, ERC721, basic DAOs, or simple staking.

We'll create a "Quantum Flux Registry" - a system for registering entities (addresses), assigning them a dynamic "Attunement Score," allowing weighted attestations between entities, implementing conditional access based on attunement, and introducing a system-wide "Flux Level" that affects interactions and decays over time. It will also include a generic timelock mechanism for scheduled operations associated with registered entities.

This incorporates concepts of reputation, dynamic parameters, conditional logic, and scheduled execution in a non-standard way.

---

## QuantumFluxRegistry

A decentralized registry for entities with a dynamic attunement (reputation) system, conditional access grants, a system-wide 'flux' parameter influencing interactions, and generic timelocked operations.

### Outline:

1.  **Core Registry:** Registering, updating, and querying entity data.
2.  **Attunement System:** Managing dynamic reputation scores through weighted attestations and decay.
3.  **Conditional Access:** Granting and checking specific access permissions between entities based on attunement.
4.  **System Parameters & Flux:** Dynamic configuration of system behaviors, including the 'Flux Level'.
5.  **Timelocked Operations:** Scheduling, canceling, and executing generic operations associated with entities.
6.  **Owner/Management:** Standard owner functions for critical configuration and withdrawal.
7.  **Query Functions:** Public functions to retrieve contract state and entity data.

### Function Summary:

1.  `registerEntity(bytes memory quantumSignature)`: Registers a new entity with an initial attunement score and associated metadata (`quantumSignature`). Requires a registration fee.
2.  `updateQuantumSignature(bytes memory newSignature)`: Allows a registered entity to update their associated metadata.
3.  `getEntityData(address entityAddress)`: Retrieves the full data structure for a registered entity.
4.  `isEntityRegistered(address entityAddress)`: Checks if an address is registered in the registry.
5.  `deactivateEntity(address entityAddress)`: Marks a registered entity as inactive (can only be done by the owner or potentially the entity itself under conditions).
6.  `reactivateEntity(address entityAddress)`: Marks a deactivated entity as active again (owner only).
7.  `attestPositiveAttunement(address entityToAttestFor)`: Allows a registered, active entity to positively attest for another registered entity, boosting their attunement score. The boost amount is weighted by the attestor's own attunement and the current flux level.
8.  `attestNegativeAttunement(address entityToAttestFor)`: Allows a registered, active entity to negatively attest for another registered entity, decreasing their attunement score. The penalty amount is weighted by the attestor's own attunement and the current flux level.
9.  `getAttunementScore(address entityAddress)`: Retrieves the current attunement score for a registered entity.
10. `applyFluxDecay()`: Can be called by anyone (potentially with a small reward/incentive mechanism, but simpler here as permissioned) to apply a time-based decay to all active entities' attunement scores based on the system decay rate. (Note: Iterating all entities is gas-prohibitive on-chain. A realistic implementation would use checkpoints or a pull mechanism. This version simulates the concept without full iteration).
11. `grantConditionalAccess(address entityToGrantAccessTo, bytes32 permissionKey)`: Allows a registered, active entity to grant a specific abstract permission (`permissionKey`) to another registered entity. Requires the grantor to have a minimum attunement.
12. `revokeConditionalAccess(address entityToRevokeAccessFrom, bytes32 permissionKey)`: Allows an entity to revoke a previously granted permission.
13. `checkConditionalAccess(address requester, address grantee, bytes32 permissionKey)`: Checks if `requester` has been granted the specific `permissionKey` by `grantee`. This is an abstract permission check for use within the contract's internal logic or by external systems.
14. `setRegistrationFee(uint256 newFee)`: Owner function to set the fee required to register a new entity.
15. `setAttunementDecayRate(uint256 newRatePermille)`: Owner function to set the percentage (in per mille, 1/1000th) of attunement score that decays per decay period when `applyFluxDecay` is called.
16. `triggerFluxShift(uint256 newFluxLevel)`: Owner function to change the system's 'Flux Level', which scales the impact of attunement changes and decay.
17. `getCurrentFluxLevel()`: Retrieves the current system Flux Level.
18. `scheduleOperationTimelock(bytes32 operationId, uint64 releaseTime)`: Schedules a generic operation, identified by `operationId`, to be executable only after `releaseTime`. Can only be scheduled by registered, active entities.
19. `cancelOperationTimelock(bytes32 operationId)`: Allows the entity who scheduled a timelock to cancel it before it's executed.
20. `executeOperationTimelock(bytes32 operationId)`: Allows anyone to execute a timelocked operation identified by `operationId` once the `releaseTime` has passed and it hasn't been cancelled. The contract *itself* doesn't know *what* `operationId` means; this is a primitive for external systems/other contracts to build upon.
21. `getOperationTimelockDetails(bytes32 operationId)`: Retrieves the details (scheduler, release time, executed/cancelled status) of a timelocked operation.
22. `withdrawFees(address payable recipient)`: Owner function to withdraw accumulated registration fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Outline:
// 1. Core Registry: Registering, updating, and querying entity data.
// 2. Attunement System: Managing dynamic reputation scores through weighted attestations and decay.
// 3. Conditional Access: Granting and checking specific access permissions between entities based on attunement.
// 4. System Parameters & Flux: Dynamic configuration of system behaviors, including the 'Flux Level'.
// 5. Timelocked Operations: Scheduling, canceling, and executing generic operations associated with entities.
// 6. Owner/Management: Standard owner functions for critical configuration and withdrawal.
// 7. Query Functions: Public functions to retrieve contract state and entity data.

// Function Summary:
// 1. registerEntity(bytes memory quantumSignature)
// 2. updateQuantumSignature(bytes memory newSignature)
// 3. getEntityData(address entityAddress)
// 4. isEntityRegistered(address entityAddress)
// 5. deactivateEntity(address entityAddress)
// 6. reactivateEntity(address entityAddress)
// 7. attestPositiveAttunement(address entityToAttestFor)
// 8. attestNegativeAttunement(address entityToAttestFor)
// 9. getAttunementScore(address entityAddress)
// 10. applyFluxDecay()
// 11. grantConditionalAccess(address entityToGrantAccessTo, bytes32 permissionKey)
// 12. revokeConditionalAccess(address entityToRevokeAccessFrom, bytes32 permissionKey)
// 13. checkConditionalAccess(address requester, address grantee, bytes32 permissionKey)
// 14. setRegistrationFee(uint256 newFee)
// 15. setAttunementDecayRate(uint256 newRatePermille)
// 16. triggerFluxShift(uint256 newFluxLevel)
// 17. getCurrentFluxLevel()
// 18. scheduleOperationTimelock(bytes32 operationId, uint64 releaseTime)
// 19. cancelOperationTimelock(bytes32 operationId)
// 20. executeOperationTimelock(bytes32 operationId)
// 21. getOperationTimelockDetails(bytes32 operationId)
// 22. withdrawFees(address payable recipient)

contract QuantumFluxRegistry {

    address private _owner;

    struct EntityData {
        address entityAddress;
        uint64 registrationTime;
        int256 attunementScore; // Can be positive or negative
        bytes quantumSignature; // Flexible metadata associated with the entity
        bool isActive;
        uint66 lastDecayAppliedTime; // Timestamp of the last time decay was applied to this entity
    }

    struct TimelockData {
        address scheduledBy;
        uint64 releaseTime;
        bool executed;
        bool cancelled;
    }

    // --- State Variables ---
    mapping(address => EntityData) private _entities;
    uint256 private _registeredEntityCount; // Simple counter for query
    mapping(address => bool) private _isRegistered; // Quick lookup
    uint256 private _registrationFee;

    // Attunement System
    int256 private constant _INITIAL_ATTUNEMENT = 1000; // Starting score
    int256 private constant _BASE_ATTEST_IMPACT = 50; // Base points added/removed per attestation
    uint256 private constant _ATTUNEMENT_SCORE_SCALE = 100; // Scale factor for score calculations (e.g., 100 means scores are int256/100)
    uint256 private constant _ATTESTOR_WEIGHT_DENOMINATOR = 1000; // How much the attestor's score (scaled) influences the impact

    // Conditional Access
    mapping(address => mapping(address => mapping(bytes32 => bool))) private _conditionalAccessGrants; // grantee => requester => permissionKey => granted
    int256 private constant _MIN_ATTUNEMENT_FOR_GRANT = 500; // Minimum score needed to grant access

    // System Parameters / Flux
    uint256 private _currentFluxLevel; // Affects attunement changes. E.g., 100 = 1x, 200 = 2x, 50 = 0.5x
    uint256 private constant _BASE_FLUX_LEVEL = 100; // The neutral flux level
    uint256 private _attunementDecayRatePermille; // Percentage (in per mille, 1/1000) decay per period
    uint64 private _decayPeriod = 1 days; // How often decay is applied

    // Timelocked Operations
    mapping(bytes32 => TimelockData) private _timelocks; // operationId => TimelockData

    // --- Events ---
    event EntityRegistered(address indexed entityAddress, uint64 registrationTime, bytes quantumSignature);
    event EntityUpdated(address indexed entityAddress, bytes newSignature);
    event EntityDeactivated(address indexed entityAddress);
    event EntityReactivated(address indexed entityAddress);
    event AttunementChanged(address indexed entityAddress, int256 oldScore, int256 newScore, address indexed byAttestor);
    event ConditionalAccessGranted(address indexed grantee, address indexed requester, bytes32 permissionKey);
    event ConditionalAccessRevoked(address indexed grantee, address indexed requester, bytes32 permissionKey);
    event RegistrationFeeUpdated(uint256 newFee);
    event AttunementDecayRateUpdated(uint256 newRatePermille);
    event FluxLevelChanged(uint256 newFluxLevel);
    event OperationTimelocked(bytes32 indexed operationId, address indexed scheduledBy, uint64 releaseTime);
    event OperationTimelockCancelled(bytes32 indexed operationId);
    event OperationTimelockExecuted(bytes32 indexed operationId);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredAndActive(address entityAddress) {
        require(_isRegistered[entityAddress], "Entity not registered");
        require(_entities[entityAddress].isActive, "Entity not active");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialRegistrationFee, uint256 initialDecayRatePermille, uint256 initialFluxLevel) {
        _owner = msg.sender;
        _registrationFee = initialRegistrationFee;
        _attunementDecayRatePermille = initialDecayRatePermille;
        _currentFluxLevel = initialFluxLevel;
    }

    // --- Core Registry Functions ---

    function registerEntity(bytes memory quantumSignature) public payable {
        require(!_isRegistered[msg.sender], "Entity already registered");
        require(msg.value >= _registrationFee, "Insufficient registration fee");

        _entities[msg.sender] = EntityData({
            entityAddress: msg.sender,
            registrationTime: uint64(block.timestamp),
            attunementScore: _INITIAL_ATTUNEMENT,
            quantumSignature: quantumSignature,
            isActive: true,
            lastDecayAppliedTime: uint64(block.timestamp) // Initialize last decay time
        });
        _isRegistered[msg.sender] = true;
        _registeredEntityCount++;

        emit EntityRegistered(msg.sender, uint64(block.timestamp), quantumSignature);
    }

    function updateQuantumSignature(bytes memory newSignature) public onlyRegisteredAndActive(msg.sender) {
        _entities[msg.sender].quantumSignature = newSignature;
        emit EntityUpdated(msg.sender, newSignature);
    }

    function getEntityData(address entityAddress) public view returns (EntityData memory) {
        require(_isRegistered[entityAddress], "Entity not registered");
        return _entities[entityAddress];
    }

    function isEntityRegistered(address entityAddress) public view returns (bool) {
        return _isRegistered[entityAddress];
    }

    function deactivateEntity(address entityAddress) public onlyOwner {
        require(_isRegistered[entityAddress], "Entity not registered");
        require(_entities[entityAddress].isActive, "Entity already inactive");
        _entities[entityAddress].isActive = false;
        emit EntityDeactivated(entityAddress);
    }

    function reactivateEntity(address entityAddress) public onlyOwner {
        require(_isRegistered[entityAddress], "Entity not registered");
        require(!_entities[entityAddress].isActive, "Entity already active");
        _entities[entityAddress].isActive = true;
        emit EntityReactivated(entityAddress);
    }

    // --- Attunement System Functions ---

    function _updateAttunement(address entityAddress, int256 scoreChange, address attestor) internal {
        EntityData storage entity = _entities[entityAddress];
        int256 oldScore = entity.attunementScore;

        // Apply attunement change, weighted by attestor's score and flux
        // Simple weighting: attestor's score relative to initial score affects impact
        int256 effectiveAttestorScore = 0;
        if (_isRegistered[attestor]) {
             effectiveAttestorScore = _entities[attestor].attunementScore;
        } else {
            // Non-registered attestor has base impact (e.g., if contract owner attests)
            effectiveAttestorScore = _INITIAL_ATTUNEMENT;
        }

        // Calculate impact scaling: (attestorScore / INITIAL_ATTUNEMENT) * (currentFlux / BASE_FLUX)
        // Need to handle potential division by zero or negative scores carefully.
        // Simplified scaling: (attestorScore / Scale) * (Flux / BaseFlux)
        int256 scaledAttestorScore = effectiveAttestorScore / int256(_ATTUNEMENT_SCORE_SCALE);
        if (scaledAttestorScore < 1) scaledAttestorScore = 1; // Prevent zero/negative scaling from attestor

        int256 fluxMultiplier = int256(_currentFluxLevel);
        if (fluxMultiplier <= 0) fluxMultiplier = int256(_BASE_FLUX_LEVEL); // Prevent zero/negative flux

        int256 weightedChange = (scoreChange * scaledAttestorScore * fluxMultiplier) / (int256(_ATTESTOR_WEIGHT_DENOMINATOR) * int256(_BASE_FLUX_LEVEL));

        entity.attunementScore += weightedChange;

        emit AttunementChanged(entityAddress, oldScore, entity.attunementScore, attestor);
    }

    function attestPositiveAttunement(address entityToAttestFor) public onlyRegisteredAndActive(msg.sender) {
        require(_isRegistered[entityToAttestFor], "Entity to attest for is not registered");
        require(msg.sender != entityToAttestFor, "Cannot attest for yourself");

        _updateAttunement(entityToAttestFor, _BASE_ATTEST_IMPACT, msg.sender);
    }

    function attestNegativeAttunement(address entityToAttestFor) public onlyRegisteredAndActive(msg.sender) {
        require(_isRegistered[entityToAttestFor], "Entity to attest for is not registered");
        require(msg.sender != entityToAttestFor, "Cannot attest for yourself");

        _updateAttunement(entityToAttestFor, -_BASE_ATTEST_IMPACT, msg.sender);
    }

    function getAttunementScore(address entityAddress) public view returns (int256) {
        require(_isRegistered[entityAddress], "Entity not registered");
        return _entities[entityAddress].attunementScore;
    }

    // NOTE: Iterating over all entities on-chain is gas-prohibitive for large registries.
    // This function is illustrative of the concept but not suitable for execution on a large dataset.
    // A real-world implementation would need a different decay mechanism (e.g., lazy decay on access, or off-chain processing).
    function applyFluxDecay() public {
        // Decay logic applied to active entities
        // This simplified version would be too expensive for many entities.
        // A pragmatic approach would require entities to 'check-in' or apply decay when accessed.
        // For demonstration, we'll show the concept, but be aware of gas limits.

        // Check a batch? No, needs external mechanism or different data structure.
        // Let's just track decay per entity on update/access for a more realistic pattern.

        // REVISED CONCEPT: Modify update functions (like attestations) and getEntityData/getAttunementScore
        // to apply decay *lazily* when an entity is accessed or updated, based on `lastDecayAppliedTime`.
        // This makes applyFluxDecay() less necessary or changes its role.

        // Let's remove this global decay function and implement lazy decay within relevant accessors/mutators.
        // The function `_applyLazyDecay` will be called internally.
         revert("Global decay function removed. Decay is applied lazily on entity access/update.");
    }

    // Internal function to apply decay based on time since last decay
    function _applyLazyDecay(address entityAddress) internal {
        EntityData storage entity = _entities[entityAddress];
        if (!entity.isActive || _attunementDecayRatePermille == 0 || _decayPeriod == 0) {
            entity.lastDecayAppliedTime = uint64(block.timestamp); // Reset timer even if no decay happens
            return;
        }

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeSinceLastDecay = currentTime - entity.lastDecayAppliedTime;

        uint256 decayPeriodsPassed = timeSinceLastDecay / _decayPeriod;

        if (decayPeriodsPassed > 0) {
            // Calculate compounded decay (or simple decay). Simple is easier/cheaper.
            // Simple decay: score -= (score * rate * periods) / 1000
            // Compounded decay: score *= (1 - rate)^periods ... tricky with int256 and fixed point math.
            // Let's use simple decay per period passed. Max periods to consider to avoid overflow?
            // Let's limit the number of periods applied in one go for gas/safety, e.g., max 100 periods.
            uint256 periodsToApply = decayPeriodsPassed > 100 ? 100 : decayPeriodsPassed;

            int256 decayAmount = (entity.attunementScore * int256(_attunementDecayRatePermille) * int256(periodsToApply)) / 1000;

            entity.attunementScore -= decayAmount;
            entity.lastDecayAppliedTime = entity.lastDecayAppliedTime + uint64(periodsToApply * _decayPeriod); // Advance decay time

            // Ensure score doesn't go excessively low (optional floor)
             if (entity.attunementScore < -_INITIAL_ATTUNEMENT * 10) { // Example floor
                 entity.attunementScore = -_INITIAL_ATTUNEMENT * 10;
             }

            // Note: No AttunementChanged event here as it's automatic decay, not an attestation.
        }
    }

    // Modify relevant functions to call _applyLazyDecay
    function attestPositiveAttunement(address entityToAttestFor) public override onlyRegisteredAndActive(msg.sender) {
        _applyLazyDecay(msg.sender); // Apply decay to attestor before weighting calculation
        _applyLazyDecay(entityToAttestFor); // Apply decay to target before updating score
        super.attestPositiveAttunement(entityToAttestFor); // Call the original logic
    }

    function attestNegativeAttunement(address entityToAttestFor) public override onlyRegisteredAndActive(msg.sender) {
        _applyLazyDecay(msg.sender); // Apply decay to attestor before weighting calculation
        _applyLazyDecay(entityToAttestFor); // Apply decay to target before updating score
        super.attestNegativeAttunement(entityToAttestFor); // Call the original logic
    }

    function getAttunementScore(address entityAddress) public view override returns (int256) {
        require(_isRegistered[entityAddress], "Entity not registered");
        // Apply decay calculation logic here for a more accurate score return,
        // but note that *state* is not changed in a view function.
        // For an *actual* updated score that reflects decay, a non-view function is needed.
        // Let's make this view function return the *current stored* score and note the lazy decay.
        // A separate function `getAttunementScoreAndApplyDecay` could be added if state update is needed on read.
        // For simplicity in this example, getAttunementScore() returns the last updated value.
        // A real system would apply decay either on read (via a non-view accessor) or write.
        return _entities[entityAddress].attunementScore;
    }

    // Function to explicitly trigger decay application for a specific entity
    // This allows external systems or the entity itself to force a score update reflecting decay
    function applyDecayForEntity(address entityAddress) public onlyRegisteredAndActive(entityAddress) {
         require(msg.sender == entityAddress || msg.sender == _owner, "Only entity or owner can trigger decay");
         _applyLazyDecay(entityAddress);
    }


    // --- Conditional Access Functions ---

    function grantConditionalAccess(address entityToGrantAccessTo, bytes32 permissionKey) public onlyRegisteredAndActive(msg.sender) {
        require(_isRegistered[entityToGrantAccessTo], "Entity to grant access to is not registered");
        require(msg.sender != entityToGrantAccessTo, "Cannot grant access to yourself");
        require(getAttunementScore(msg.sender) >= _MIN_ATTUNEMENT_FOR_GRANT, "Attunement score too low to grant access");

        _conditionalAccessGrants[entityToGrantAccessTo][msg.sender][permissionKey] = true; // grantee => requester => permissionKey
        emit ConditionalAccessGranted(entityToGrantAccessTo, msg.sender, permissionKey);
    }

    function revokeConditionalAccess(address entityToRevokeAccessFrom, bytes32 permissionKey) public onlyRegisteredAndActive(msg.sender) {
        require(_isRegistered[entityToRevokeAccessFrom], "Entity to revoke access from is not registered");
        require(msg.sender != entityToRevokeAccessFrom, "Cannot revoke access from yourself");

        _conditionalAccessGrants[entityToRevokeAccessFrom][msg.sender][permissionKey] = false;
        emit ConditionalAccessRevoked(entityToRevokeAccessFrom, msg.sender, permissionKey);
    }

    function checkConditionalAccess(address grantee, address requester, bytes32 permissionKey) public view returns (bool) {
        // Check if 'requester' was granted 'permissionKey' by 'grantee'
        return _conditionalAccessGrants[grantee][requester][permissionKey];
    }

    // --- System Parameters / Flux Functions ---

    function setRegistrationFee(uint256 newFee) public onlyOwner {
        _registrationFee = newFee;
        emit RegistrationFeeUpdated(newFee);
    }

    function setAttunementDecayRate(uint256 newRatePermille) public onlyOwner {
        require(newRatePermille <= 1000, "Decay rate cannot exceed 1000 permille (100%)");
        _attunementDecayRatePermille = newRatePermille;
        emit AttunementDecayRateUpdated(newRatePermille);
    }

    function triggerFluxShift(uint256 newFluxLevel) public onlyOwner {
         // Can add requirements/logic here for how flux shifts (e.g., smooth transitions, limits)
        _currentFluxLevel = newFluxLevel;
        emit FluxLevelChanged(newFluxLevel);
    }

    function getCurrentFluxLevel() public view returns (uint256) {
        return _currentFluxLevel;
    }

    // --- Timelocked Operations Functions ---

    function scheduleOperationTimelock(bytes32 operationId, uint64 releaseTime) public onlyRegisteredAndActive(msg.sender) {
        require(releaseTime > block.timestamp, "Release time must be in the future");
        require(_timelocks[operationId].scheduledBy == address(0), "Operation ID already scheduled"); // Check if ID is unused

        _timelocks[operationId] = TimelockData({
            scheduledBy: msg.sender,
            releaseTime: releaseTime,
            executed: false,
            cancelled: false
        });

        emit OperationTimelocked(operationId, msg.sender, releaseTime);
    }

    function cancelOperationTimelock(bytes32 operationId) public onlyRegisteredAndActive(msg.sender) {
        TimelockData storage timelock = _timelocks[operationId];
        require(timelock.scheduledBy != address(0), "Operation ID not scheduled");
        require(timelock.scheduledBy == msg.sender, "Only scheduler can cancel");
        require(!timelock.executed, "Cannot cancel an executed operation");
        require(!timelock.cancelled, "Operation already cancelled");
        require(timelock.releaseTime > block.timestamp, "Cannot cancel operation after release time");

        timelock.cancelled = true;
        emit OperationTimelockCancelled(operationId);
    }

    function executeOperationTimelock(bytes32 operationId) public {
        TimelockData storage timelock = _timelocks[operationId];
        require(timelock.scheduledBy != address(0), "Operation ID not scheduled");
        require(!timelock.executed, "Operation already executed");
        require(!timelock.cancelled, "Operation was cancelled");
        require(timelock.releaseTime <= block.timestamp, "Operation release time not reached");

        timelock.executed = true;
        // Note: This contract itself doesn't know *what* the operation is.
        // External contracts or systems calling this method must interpret the operationId
        // and perform the actual desired action *after* this function successfully executes.
        // This contract only serves as a decentralized scheduler and state manager for the lock.

        emit OperationTimelockExecuted(operationId);
    }

    function getOperationTimelockDetails(bytes32 operationId) public view returns (TimelockData memory) {
        require(_timelocks[operationId].scheduledBy != address(0), "Operation ID not scheduled");
        return _timelocks[operationId];
    }

    // --- Owner/Management Functions ---

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        _owner = newOwner;
    }

    function withdrawFees(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Recipient cannot be the zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(recipient, balance);
    }

    // --- Query Functions ---

    function getRegisteredEntityCount() public view returns (uint256) {
        return _registeredEntityCount;
    }

    function getEntityStatus(address entityAddress) public view returns (bool isActive) {
        require(_isRegistered[entityAddress], "Entity not registered");
        return _entities[entityAddress].isActive;
    }

    // Added for clarity, though Attunement is covered by getAttunementScore
    function getEntityRegistrationTime(address entityAddress) public view returns (uint64) {
        require(_isRegistered[entityAddress], "Entity not registered");
        return _entities[entityAddress].registrationTime;
    }

     // Added to check a specific permission grant status
    function hasConditionalAccess(address grantee, address requester, bytes32 permissionKey) public view returns (bool) {
        return checkConditionalAccess(grantee, requester, permissionKey);
    }
}
```