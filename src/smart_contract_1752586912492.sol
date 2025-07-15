That's an exciting challenge! Creating something truly unique in the open-source blockchain space is tough, but focusing on a specific, advanced concept that integrates multiple ideas can lead to something distinct.

Let's imagine a contract called **"Chronoscribe Nexus"**.

**Core Concept:** The Chronoscribe Nexus is a decentralized, programmable, time-aware ledger for verifiable "Attestations." Unlike simple NFTs or data registries, Attestations here are dynamic, can have conditional states, expiry, and can even trigger or be influenced by on-chain time-based events or external oracle data (simulated). It's designed for establishing programmable facts, agreements, or milestones that evolve over time or based on conditions.

**Advanced Concepts Integrated:**

1.  **Dynamic On-Chain Data/Metadata:** Attestations aren't static NFTs; their internal state and perceived "value" can change based on time, external conditions, or internal logic.
2.  **Time-Based State Transitions:** Attestations can automatically (or via user interaction) change status (e.g., "active" to "expired," "pending" to "fulfilled") based on timestamps.
3.  **Programmable Attestation Logic:** Beyond simple creation, Attestations can have predefined "phases" or "milestones" that need to be met, akin to a multi-stage agreement.
4.  **Delegated Authority/Roles:** Complex roles for attestation creation, validation, and dispute resolution.
5.  **Reputation/Credibility (Basic):** Attestations from "trusted sources" could be weighted differently or restricted.
6.  **Oracle Integration (Conceptual/Simulated):** The contract can conceptually interact with external data (e.g., weather, market price, external event confirmation) to validate or influence Attestation states, using an `updateOracleData` function as a placeholder.
7.  **Category-Based Logic:** Attestations belong to categories, and each category can have different rules (e.g., mutability, expiry defaults, required roles).

---

## Chronoscribe Nexus Smart Contract

**Solidity Version:** `^0.8.0`

**Concept Overview:**

The `ChronoscribeNexus` contract acts as a robust, time-sensitive, and programmable registry for decentralized "Attestations." Each Attestation represents a verifiable fact, assertion, or agreement that can evolve through different states and phases, driven by timestamps, predefined logic, or external inputs. It aims to provide a granular and flexible framework for managing complex, time-bound on-chain commitments.

**Key Features:**

*   **Attestation Management:** Create, update, revoke, and query detailed Attestations.
*   **Time-Based Dynamics:** Attestations can have expiry dates, and their status can automatically transition based on time.
*   **Multi-Phase Attestations:** Define Attestations that progress through distinct stages (e.g., "Proposed", "Active", "Fulfilled", "Archived").
*   **Categorization:** Organize Attestations into categories, each with custom rules and default parameters.
*   **Role-Based Access Control:** Granular permissions for creating categories, setting roles, and managing specific types of Attestations.
*   **Dispute Mechanism:** Built-in flagging for disputed Attestations and a resolution process.
*   **Oracle Integration Placeholder:** Functions to conceptually update Attestation states based on external data feeds (simulated for simplicity).

**Function Summary:**

**I. Core Attestation Management (CRUD & Lifecycle)**

1.  `attest(string memory _data, address _subject, uint256 _expiryTimestamp, uint256 _categoryId, AttestationPhase _initialPhase)`: Creates a new Attestation.
2.  `updateAttestationData(uint256 _attestationId, string memory _newData)`: Updates the `data` of an existing Attestation.
3.  `updateAttestationSubject(uint256 _attestationId, address _newSubject)`: Changes the `subject` of an Attestation.
4.  `revokeAttestation(uint256 _attestationId)`: Invalidates an Attestation by marking its status as `Revoked`.
5.  `getAttestation(uint256 _attestationId)`: Retrieves all details of a specific Attestation.
6.  `extendAttestationExpiry(uint256 _attestationId, uint256 _newExpiryTimestamp)`: Extends the expiry time of an Attestation.
7.  `advanceAttestationPhase(uint256 _attestationId, AttestationPhase _newPhase)`: Moves an Attestation to its next logical phase.
8.  `markAttestationAsFulfilled(uint256 _attestationId)`: Marks an Attestation as `Fulfilled`.
9.  `markAttestationAsDisputed(uint256 _attestationId)`: Flags an Attestation as `Disputed`.
10. `resolveAttestationDispute(uint256 _attestationId)`: Resolves a dispute, reverting the status to `Active` or `Fulfilled`.

**II. Attestation Categorization & Configuration**

11. `createAttestationCategory(string memory _name, string memory _description, bool _isMutableByDefault, uint256 _defaultExpiryOffset)`: Creates a new category for Attestations.
12. `updateCategoryMetadata(uint256 _categoryId, string memory _newName, string memory _newDescription)`: Updates the name/description of a category.
13. `toggleCategoryMutability(uint256 _categoryId, bool _canBeMutable)`: Sets whether Attestations in a category can be updated after creation.
14. `setDefaultCategoryExpiryOffset(uint256 _categoryId, uint256 _newOffset)`: Sets a default expiry duration for new Attestations in a category.

**III. Role & Permission Management**

15. `setAttesterRole(address _account, bool _canAttest)`: Grants or revokes the general attester role.
16. `setCategorySpecificAttesterRole(uint256 _categoryId, address _account, bool _canAttest)`: Grants or revokes attester role for a specific category.
17. `setDisputeResolverRole(address _account, bool _canResolve)`: Grants or revokes the role to resolve disputes.

**IV. Query & Utility Functions**

18. `getAttestationsBySubject(address _subject)`: Returns a list of Attestation IDs where the given address is the subject.
19. `getAttestationsByAttester(address _attester)`: Returns a list of Attestation IDs made by a given attester.
20. `getExpiredAttestations()`: Returns a list of Attestation IDs that have passed their expiry date and are still active.
21. `updateAttestationStatusOnExpiry(uint256 _attestationId)`: Manually triggers an update to `Expired` if the attestation's expiry timestamp has passed. (Can be called by anyone).
22. `getAttestationsByCategory(uint256 _categoryId)`: Returns all Attestation IDs belonging to a specific category.
23. `getTotalAttestations()`: Returns the total number of Attestations created.

**V. Advanced / Oracle Integration (Conceptual)**

24. `simulateOracleUpdate(uint256 _attestationId, string memory _oracleData, bool _isValid)`: Simulates an oracle pushing data, potentially affecting an Attestation's state or validity. This is a placeholder for real oracle integration (e.g., Chainlink).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ChronoscribeNexus
 * @dev A decentralized, programmable, time-aware ledger for verifiable "Attestations".
 *      Attestations are dynamic, can have conditional states, expiry, and can even trigger
 *      or be influenced by on-chain time-based events or external oracle data (simulated).
 *      It's designed for establishing programmable facts, agreements, or milestones that evolve
 *      over time or based on conditions.
 */
contract ChronoscribeNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum AttestationStatus {
        Active,
        Expired,
        Revoked,
        Fulfilled,
        Disputed
    }

    enum AttestationPhase {
        Proposed,
        Active,
        PendingVerification,
        Fulfilled,
        Archived
    }

    // --- Structs ---

    /**
     * @dev Represents a single verifiable assertion or fact.
     * @param id Unique identifier for the attestation.
     * @param attester Address that created the attestation.
     * @param subject Address or entity the attestation is about.
     * @param data Arbitrary string data describing the attestation.
     * @param timestamp Creation timestamp.
     * @param expiryTimestamp Timestamp when the attestation expires. 0 for no expiry.
     * @param status Current status of the attestation (e.g., Active, Expired).
     * @param currentPhase Current operational phase of the attestation.
     * @param categoryId The ID of the category this attestation belongs to.
     * @param isMutable Whether the attestation's data can be updated.
     * @param oracleValidated A flag indicating if an oracle has validated this attestation (simulated).
     */
    struct Attestation {
        uint256 id;
        address attester;
        address subject;
        string data;
        uint256 timestamp;
        uint256 expiryTimestamp;
        AttestationStatus status;
        AttestationPhase currentPhase;
        uint256 categoryId;
        bool isMutable;
        bool oracleValidated;
    }

    /**
     * @dev Defines a category for attestations, allowing for default behaviors.
     * @param name Name of the category (e.g., "IdentityProof", "Agreement", "Milestone").
     * @param description Description of what attestations in this category represent.
     * @param isMutableByDefault Default mutability for new attestations in this category.
     * @param defaultExpiryOffset Default time offset (in seconds) for expiry when creating new attestations.
     * @param exists Flag to confirm category has been initialized.
     */
    struct AttestationCategory {
        string name;
        string description;
        bool isMutableByDefault;
        uint256 defaultExpiryOffset; // in seconds
        bool exists;
    }

    // --- State Variables ---

    Counters.Counter private _attestationIds;
    Counters.Counter private _categoryIds;

    // Mapping from attestation ID to Attestation struct
    mapping(uint256 => Attestation) public attestations;
    // Mapping from category ID to AttestationCategory struct
    mapping(uint256 => AttestationCategory) public attestationCategories;

    // Mapping from subject address to a list of attestation IDs about them
    mapping(address => uint256[]) public subjectAttestations;
    // Mapping from attester address to a list of attestation IDs they created
    mapping(address => uint256[]) public attesterAttestations;
    // Mapping from category ID to a list of attestation IDs in that category
    mapping(uint256 => uint256[]) public categoryAttestations;

    // Role-based access control mappings
    mapping(address => bool) public isAttester;
    mapping(uint256 => mapping(address => bool)) public isCategorySpecificAttester;
    mapping(address => bool) public isDisputeResolver;

    // --- Events ---
    event AttestationCreated(uint256 indexed id, address indexed attester, address indexed subject, uint256 categoryId, string data, uint256 expiryTimestamp);
    event AttestationUpdated(uint256 indexed id, string newData);
    event AttestationRevoked(uint256 indexed id, address indexed revoker);
    event AttestationExpiryExtended(uint256 indexed id, uint256 newExpiryTimestamp);
    event AttestationPhaseAdvanced(uint256 indexed id, AttestationPhase oldPhase, AttestationPhase newPhase);
    event AttestationStatusChanged(uint256 indexed id, AttestationStatus oldStatus, AttestationStatus newStatus);
    event AttestationMarkedAsDisputed(uint256 indexed id);
    event AttestationDisputeResolved(uint256 indexed id);

    event AttestationCategoryCreated(uint256 indexed id, string name, address indexed creator);
    event AttestationCategoryUpdated(uint256 indexed id, string newName, string newDescription);
    event CategoryMutabilityToggled(uint256 indexed id, bool canBeMutable);
    event DefaultCategoryExpiryOffsetSet(uint256 indexed id, uint256 newOffset);

    event AttesterRoleSet(address indexed account, bool granted);
    event CategorySpecificAttesterRoleSet(uint256 indexed categoryId, address indexed account, bool granted);
    event DisputeResolverRoleSet(address indexed account, bool granted);

    event OracleDataSimulated(uint256 indexed attestationId, string oracleData, bool isValid);

    // --- Modifiers ---
    modifier onlyAttester() {
        require(isAttester[msg.sender], "ChronoscribeNexus: Caller is not a general attester");
        _;
    }

    modifier onlyCategoryAttester(uint256 _categoryId) {
        require(isCategorySpecificAttester[_categoryId][msg.sender] || isAttester[msg.sender], "ChronoscribeNexus: Caller is not an attester for this category");
        _;
    }

    modifier onlyDisputeResolver() {
        require(isDisputeResolver[msg.sender] || msg.sender == owner(), "ChronoscribeNexus: Caller is not a dispute resolver or owner");
        _;
    }

    modifier isValidAttestation(uint256 _attestationId) {
        require(_attestationId > 0 && _attestationId <= _attestationIds.current(), "ChronoscribeNexus: Invalid Attestation ID");
        _;
    }

    modifier attestationExists(uint256 _attestationId) {
        require(attestations[_attestationId].id != 0, "ChronoscribeNexus: Attestation does not exist");
        _;
    }

    modifier attestationNotRevoked(uint256 _attestationId) {
        require(attestations[_attestationId].status != AttestationStatus.Revoked, "ChronoscribeNexus: Attestation is revoked");
        _;
    }

    modifier attestationNotFulfilled(uint256 _attestationId) {
        require(attestations[_attestationId].status != AttestationStatus.Fulfilled, "ChronoscribeNexus: Attestation is already fulfilled");
        _;
    }

    modifier categoryExists(uint256 _categoryId) {
        require(attestationCategories[_categoryId].exists, "ChronoscribeNexus: Category does not exist");
        _;
    }

    constructor() {
        // Owner is automatically set by Ownable
        // Create a default "General" category
        _categoryIds.increment();
        uint256 defaultId = _categoryIds.current();
        attestationCategories[defaultId] = AttestationCategory(
            "General",
            "A general category for miscellaneous attestations.",
            true, // isMutableByDefault
            0,    // defaultExpiryOffset (no default expiry)
            true  // exists
        );
        emit AttestationCategoryCreated(defaultId, "General", msg.sender);

        // Grant owner general attester role and dispute resolver role by default
        isAttester[msg.sender] = true;
        isDisputeResolver[msg.sender] = true;
        emit AttesterRoleSet(msg.sender, true);
        emit DisputeResolverRoleSet(msg.sender, true);
    }

    // --- I. Core Attestation Management (CRUD & Lifecycle) ---

    /**
     * @dev Creates a new Attestation.
     * @param _data Arbitrary string data for the attestation.
     * @param _subject The address the attestation is about.
     * @param _expiryTimestamp Specific Unix timestamp when the attestation expires (0 for no expiry).
     * @param _categoryId The ID of the category this attestation belongs to.
     * @param _initialPhase The initial phase of the attestation.
     */
    function attest(
        string memory _data,
        address _subject,
        uint256 _expiryTimestamp,
        uint256 _categoryId,
        AttestationPhase _initialPhase
    ) external nonReentrant categoryExists(_categoryId) onlyCategoryAttester(_categoryId) returns (uint256) {
        _attestationIds.increment();
        uint256 newId = _attestationIds.current();
        uint256 currentTimestamp = block.timestamp;

        AttestationCategory storage category = attestationCategories[_categoryId];
        uint256 finalExpiryTimestamp = _expiryTimestamp;
        if (finalExpiryTimestamp == 0 && category.defaultExpiryOffset > 0) {
            finalExpiryTimestamp = currentTimestamp + category.defaultExpiryOffset;
        }

        attestations[newId] = Attestation({
            id: newId,
            attester: msg.sender,
            subject: _subject,
            data: _data,
            timestamp: currentTimestamp,
            expiryTimestamp: finalExpiryTimestamp,
            status: AttestationStatus.Active,
            currentPhase: _initialPhase,
            categoryId: _categoryId,
            isMutable: category.isMutableByDefault,
            oracleValidated: false
        });

        subjectAttestations[_subject].push(newId);
        attesterAttestations[msg.sender].push(newId);
        categoryAttestations[_categoryId].push(newId);

        emit AttestationCreated(newId, msg.sender, _subject, _categoryId, _data, finalExpiryTimestamp);
        return newId;
    }

    /**
     * @dev Updates the data of an existing Attestation. Requires attestation to be mutable and sender to be the attester.
     * @param _attestationId The ID of the attestation to update.
     * @param _newData The new string data.
     */
    function updateAttestationData(uint256 _attestationId, string memory _newData)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender, "ChronoscribeNexus: Only the original attester can update its data.");
        require(att.isMutable, "ChronoscribeNexus: This attestation is immutable.");

        att.data = _newData;
        emit AttestationUpdated(_attestationId, _newData);
    }

    /**
     * @dev Updates the subject of an existing Attestation. Only callable by the original attester.
     * @param _attestationId The ID of the attestation to update.
     * @param _newSubject The new subject address.
     */
    function updateAttestationSubject(uint256 _attestationId, address _newSubject)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender, "ChronoscribeNexus: Only the original attester can update its subject.");

        // Remove from old subject's list
        uint256[] storage oldSubjectAtts = subjectAttestations[att.subject];
        for (uint256 i = 0; i < oldSubjectAtts.length; i++) {
            if (oldSubjectAtts[i] == _attestationId) {
                oldSubjectAtts[i] = oldSubjectAtts[oldSubjectAtts.length - 1];
                oldSubjectAtts.pop();
                break;
            }
        }

        att.subject = _newSubject;
        subjectAttestations[_newSubject].push(_attestationId);

        emit AttestationUpdated(_attestationId, att.data); // Re-emit update with existing data for subject change clarity
    }

    /**
     * @dev Revokes an Attestation, rendering it invalid. Only callable by the attester or owner.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender || msg.sender == owner(), "ChronoscribeNexus: Only attester or owner can revoke.");

        AttestationStatus oldStatus = att.status;
        att.status = AttestationStatus.Revoked;
        emit AttestationRevoked(_attestationId, msg.sender);
        emit AttestationStatusChanged(_attestationId, oldStatus, AttestationStatus.Revoked);
    }

    /**
     * @dev Retrieves all details of a specific Attestation.
     * @param _attestationId The ID of the attestation to retrieve.
     * @return Attestation struct containing all details.
     */
    function getAttestation(uint256 _attestationId) public view attestationExists(_attestationId) returns (Attestation memory) {
        return attestations[_attestationId];
    }

    /**
     * @dev Extends the expiry timestamp of an Attestation. Only callable by the original attester.
     * @param _attestationId The ID of the attestation.
     * @param _newExpiryTimestamp The new expiry timestamp. Must be in the future and later than current expiry if any.
     */
    function extendAttestationExpiry(uint256 _attestationId, uint256 _newExpiryTimestamp)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender, "ChronoscribeNexus: Only the original attester can extend expiry.");
        require(_newExpiryTimestamp > block.timestamp, "ChronoscribeNexus: New expiry must be in the future.");
        if (att.expiryTimestamp > 0) {
            require(_newExpiryTimestamp > att.expiryTimestamp, "ChronoscribeNexus: New expiry must be later than current expiry.");
        }

        att.expiryTimestamp = _newExpiryTimestamp;
        // If it was expired, change status back to active
        if (att.status == AttestationStatus.Expired && att.expiryTimestamp > block.timestamp) {
            att.status = AttestationStatus.Active;
            emit AttestationStatusChanged(_attestationId, AttestationStatus.Expired, AttestationStatus.Active);
        }
        emit AttestationExpiryExtended(_attestationId, _newExpiryTimestamp);
    }

    /**
     * @dev Advances an Attestation to its next logical phase. Requires sender to be attester or authorized.
     * @param _attestationId The ID of the attestation.
     * @param _newPhase The phase to transition to.
     */
    function advanceAttestationPhase(uint256 _attestationId, AttestationPhase _newPhase)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender || isCategorySpecificAttester[att.categoryId][msg.sender] || isAttester[msg.sender] || msg.sender == owner(),
            "ChronoscribeNexus: Not authorized to advance phase.");
        require(_newPhase > att.currentPhase, "ChronoscribeNexus: Phase can only advance, not regress."); // Enforce forward progression

        AttestationPhase oldPhase = att.currentPhase;
        att.currentPhase = _newPhase;
        emit AttestationPhaseAdvanced(_attestationId, oldPhase, _newPhase);
    }

    /**
     * @dev Marks an Attestation as Fulfilled. Can only be done by attester or dispute resolver.
     * @param _attestationId The ID of the attestation to mark as fulfilled.
     */
    function markAttestationAsFulfilled(uint256 _attestationId)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender || isDisputeResolver[msg.sender] || msg.sender == owner(),
            "ChronoscribeNexus: Only attester, dispute resolver, or owner can fulfill.");

        AttestationStatus oldStatus = att.status;
        att.status = AttestationStatus.Fulfilled;
        emit AttestationStatusChanged(_attestationId, oldStatus, AttestationStatus.Fulfilled);
    }

    /**
     * @dev Marks an Attestation as Disputed. Can be done by anyone who is the subject or attester, or owner.
     * @param _attestationId The ID of the attestation to mark as disputed.
     */
    function markAttestationAsDisputed(uint256 _attestationId)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        require(att.attester == msg.sender || att.subject == msg.sender || msg.sender == owner(),
            "ChronoscribeNexus: Only attester, subject, or owner can mark as disputed.");
        require(att.status != AttestationStatus.Disputed, "ChronoscribeNexus: Attestation is already disputed.");

        AttestationStatus oldStatus = att.status;
        att.status = AttestationStatus.Disputed;
        emit AttestationMarkedAsDisputed(_attestationId);
        emit AttestationStatusChanged(_attestationId, oldStatus, AttestationStatus.Disputed);
    }

    /**
     * @dev Resolves a dispute for an Attestation. Only callable by a dispute resolver or owner.
     * @param _attestationId The ID of the attestation to resolve dispute for.
     */
    function resolveAttestationDispute(uint256 _attestationId)
        external
        nonReentrant
        attestationExists(_attestationId)
        onlyDisputeResolver()
    {
        Attestation storage att = attestations[_attestationId];
        require(att.status == AttestationStatus.Disputed, "ChronoscribeNexus: Attestation is not in disputed status.");

        AttestationStatus oldStatus = att.status;
        // Revert to Active if not fulfilled, or Fulfilled if it was previously marked fulfilled before dispute
        if (att.currentPhase == AttestationPhase.Fulfilled) {
            att.status = AttestationStatus.Fulfilled;
        } else {
            att.status = AttestationStatus.Active;
        }
        emit AttestationDisputeResolved(_attestationId);
        emit AttestationStatusChanged(_attestationId, oldStatus, att.status);
    }

    // --- II. Attestation Categorization & Configuration ---

    /**
     * @dev Creates a new category for Attestations. Only callable by the contract owner.
     * @param _name Name of the category.
     * @param _description Description of the category.
     * @param _isMutableByDefault Default mutability for new attestations in this category.
     * @param _defaultExpiryOffset Default expiry offset in seconds for new attestations.
     * @return The ID of the newly created category.
     */
    function createAttestationCategory(
        string memory _name,
        string memory _description,
        bool _isMutableByDefault,
        uint256 _defaultExpiryOffset
    ) external onlyOwner returns (uint256) {
        _categoryIds.increment();
        uint256 newId = _categoryIds.current();
        attestationCategories[newId] = AttestationCategory({
            name: _name,
            description: _description,
            isMutableByDefault: _isMutableByDefault,
            defaultExpiryOffset: _defaultExpiryOffset,
            exists: true
        });
        emit AttestationCategoryCreated(newId, _name, msg.sender);
        return newId;
    }

    /**
     * @dev Updates the name and description of an existing category. Only callable by the contract owner.
     * @param _categoryId The ID of the category to update.
     * @param _newName The new name for the category.
     * @param _newDescription The new description for the category.
     */
    function updateCategoryMetadata(uint256 _categoryId, string memory _newName, string memory _newDescription)
        external
        onlyOwner
        categoryExists(_categoryId)
    {
        AttestationCategory storage category = attestationCategories[_categoryId];
        category.name = _newName;
        category.description = _newDescription;
        emit AttestationCategoryUpdated(_categoryId, _newName, _newDescription);
    }

    /**
     * @dev Toggles whether attestations in a specific category are mutable by default. Only callable by owner.
     * @param _categoryId The ID of the category.
     * @param _canBeMutable True if attestations should be mutable by default, false otherwise.
     */
    function toggleCategoryMutability(uint256 _categoryId, bool _canBeMutable)
        external
        onlyOwner
        categoryExists(_categoryId)
    {
        attestationCategories[_categoryId].isMutableByDefault = _canBeMutable;
        emit CategoryMutabilityToggled(_categoryId, _canBeMutable);
    }

    /**
     * @dev Sets the default expiry offset for new attestations in a category. Only callable by owner.
     * @param _categoryId The ID of the category.
     * @param _newOffset The new default expiry offset in seconds.
     */
    function setDefaultCategoryExpiryOffset(uint256 _categoryId, uint256 _newOffset)
        external
        onlyOwner
        categoryExists(_categoryId)
    {
        attestationCategories[_categoryId].defaultExpiryOffset = _newOffset;
        emit DefaultCategoryExpiryOffsetSet(_categoryId, _newOffset);
    }

    // --- III. Role & Permission Management ---

    /**
     * @dev Grants or revokes the general 'attester' role. General attesters can attest in any category.
     * @param _account The address to set the role for.
     * @param _canAttest True to grant, false to revoke.
     */
    function setAttesterRole(address _account, bool _canAttest) external onlyOwner {
        require(_account != address(0), "ChronoscribeNexus: Invalid address");
        isAttester[_account] = _canAttest;
        emit AttesterRoleSet(_account, _canAttest);
    }

    /**
     * @dev Grants or revokes the 'category-specific attester' role for a given category.
     * @param _categoryId The ID of the category.
     * @param _account The address to set the role for.
     * @param _canAttest True to grant, false to revoke.
     */
    function setCategorySpecificAttesterRole(uint256 _categoryId, address _account, bool _canAttest)
        external
        onlyOwner
        categoryExists(_categoryId)
    {
        require(_account != address(0), "ChronoscribeNexus: Invalid address");
        isCategorySpecificAttester[_categoryId][_account] = _canAttest;
        emit CategorySpecificAttesterRoleSet(_categoryId, _account, _canAttest);
    }

    /**
     * @dev Grants or revokes the 'dispute resolver' role. Dispute resolvers can resolve disputes for any attestation.
     * @param _account The address to set the role for.
     * @param _canResolve True to grant, false to revoke.
     */
    function setDisputeResolverRole(address _account, bool _canResolve) external onlyOwner {
        require(_account != address(0), "ChronoscribeNexus: Invalid address");
        isDisputeResolver[_account] = _canResolve;
        emit DisputeResolverRoleSet(_account, _canResolve);
    }

    // --- IV. Query & Utility Functions ---

    /**
     * @dev Returns a list of Attestation IDs where the given address is the subject.
     * @param _subject The address to query for.
     * @return An array of Attestation IDs.
     */
    function getAttestationsBySubject(address _subject) public view returns (uint256[] memory) {
        return subjectAttestations[_subject];
    }

    /**
     * @dev Returns a list of Attestation IDs made by a given attester.
     * @param _attester The address of the attester to query for.
     * @return An array of Attestation IDs.
     */
    function getAttestationsByAttester(address _attester) public view returns (uint256[] memory) {
        return attesterAttestations[_attester];
    }

    /**
     * @dev Returns a list of Attestation IDs that have passed their expiry date and are still active.
     *      Note: This function iterates, potentially gas-intensive for many attestations.
     * @return An array of Attestation IDs.
     */
    function getExpiredAttestations() public view returns (uint256[] memory) {
        uint256[] memory expiredIds = new uint256[](0);
        for (uint256 i = 1; i <= _attestationIds.current(); i++) {
            Attestation storage att = attestations[i];
            if (att.id != 0 && att.expiryTimestamp > 0 && att.expiryTimestamp <= block.timestamp && att.status == AttestationStatus.Active) {
                expiredIds = _appendToArray(expiredIds, i);
            }
        }
        return expiredIds;
    }

    /**
     * @dev Updates an Attestation's status to `Expired` if its expiry timestamp has passed.
     *      Can be called by anyone (e.g., an automated bot) to maintain state, gas paid by caller.
     * @param _attestationId The ID of the attestation to check and update.
     */
    function updateAttestationStatusOnExpiry(uint256 _attestationId)
        external
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        if (att.expiryTimestamp > 0 && att.expiryTimestamp <= block.timestamp && att.status == AttestationStatus.Active) {
            AttestationStatus oldStatus = att.status;
            att.status = AttestationStatus.Expired;
            emit AttestationStatusChanged(_attestationId, oldStatus, AttestationStatus.Expired);
        }
    }

    /**
     * @dev Returns all Attestation IDs belonging to a specific category.
     * @param _categoryId The ID of the category.
     * @return An array of Attestation IDs.
     */
    function getAttestationsByCategory(uint256 _categoryId) public view categoryExists(_categoryId) returns (uint256[] memory) {
        return categoryAttestations[_categoryId];
    }

    /**
     * @dev Returns the total number of Attestations created so far.
     * @return The total count.
     */
    function getTotalAttestations() public view returns (uint256) {
        return _attestationIds.current();
    }

    // --- V. Advanced / Oracle Integration (Conceptual) ---

    /**
     * @dev Simulates an external oracle pushing data related to an Attestation.
     *      In a real scenario, this would be restricted to a trusted oracle address.
     *      This function demonstrates how external data *could* influence Attestation state.
     * @param _attestationId The ID of the attestation to update.
     * @param _oracleData A string representing the data from the oracle.
     * @param _isValid A boolean indicating if the oracle data validates the attestation's conditions.
     */
    function simulateOracleUpdate(uint256 _attestationId, string memory _oracleData, bool _isValid)
        external
        onlyOwner // For demonstration, only owner can simulate oracle updates
        nonReentrant
        attestationExists(_attestationId)
        attestationNotRevoked(_attestationId)
        attestationNotFulfilled(_attestationId)
    {
        Attestation storage att = attestations[_attestationId];
        // Example: If oracle data confirms validity, mark as oracle validated and perhaps advance phase
        att.oracleValidated = _isValid;
        if (_isValid && att.currentPhase == AttestationPhase.PendingVerification) {
            att.currentPhase = AttestationPhase.Active; // Or Fulfilled, depending on logic
            emit AttestationPhaseAdvanced(_attestationId, AttestationPhase.PendingVerification, AttestationPhase.Active);
        }
        emit OracleDataSimulated(_attestationId, _oracleData, _isValid);
    }

    // --- Internal Utility Functions ---

    /**
     * @dev Helper function to append an element to a dynamic array in memory.
     * @param _array The array to append to.
     * @param _element The element to append.
     * @return The new array with the element appended.
     */
    function _appendToArray(uint256[] memory _array, uint256 _element) internal pure returns (uint256[] memory) {
        uint256 newLength = _array.length + 1;
        uint256[] memory newArray = new uint256[](newLength);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[newLength - 1] = _element;
        return newArray;
    }
}
```