Okay, let's design a creative, advanced, and hopefully non-duplicated smart contract concept. How about a decentralized "Skill Tree" or "Achievement Network" where users earn progressive access and status based on verifiable "Attestations" made by others or even other contracts.

This system isn't just minting tokens or basic voting. It's about building an on-chain reputation/capability profile based on conditional, time-sensitive, and potentially challengeable claims.

**Concept Name:** Verifiable Attestation and Progressive Access (VAPA) System

**Core Idea:** Users accumulate "Attestations" (claims made about them by others) related to skills, achievements, participation, or verification. These attestations, weighted by type and potentially the attester's own standing, contribute to a dynamic "Reputation Score" and unlock "Progression Levels." Access to certain functions or resources within *this* contract or even other integrated contracts can be gated by minimum reputation or specific attested achievements.

**Advanced/Creative Aspects:**

1.  **Dynamic Reputation:** Reputation isn't static; it's calculated based on current, non-revoked, non-disputed attestations and potentially decays or is weighted over time (though time decay might be gas-intensive, we can design for it).
2.  **Claim Types & Weights:** Different types of attestations carry different significance, configurable by an admin (e.g., "Skill Verified" is high value, "Association Member" is medium, "Warning" is negative).
3.  **Progression Levels:** Abstract levels unlocked by combinations of reputation score and specific attestation requirements (e.g., Level 1 needs 100 rep; Level 2 needs 500 rep AND an "Expert" attestation).
4.  **Conditional Access:** Functions that can *only* be called if the caller meets certain reputation or progression level criteria.
5.  **Attestation Revocation/Dispute:** Mechanisms for attesters to retract claims and for subjects of attestations to dispute false claims (requiring an admin/DAO to resolve).
6.  **Metadata/Evidence Links:** Attestations can include hashes linking to off-chain data or evidence.

**Outline:**

1.  **License and Pragma**
2.  **Imports** (e.g., OpenZeppelin for Ownable, Pausable)
3.  **Contract Definition** (inheriting Ownable, Pausable)
4.  **Events:** To log key actions (attestation, revocation, dispute, resolution, reputation update, level unlock, gated access).
5.  **Structs:**
    *   `Attestation`: Represents a single verifiable claim.
6.  **State Variables:**
    *   Counters for attestations.
    *   Mappings to store `Attestation` structs by ID.
    *   Mappings to track attestation IDs by subject (`about`) and attester.
    *   Mapping for user reputation scores (`int256` for positive/negative).
    *   Mapping for weights associated with `bytes32` claim types.
    *   Mappings for progression level requirements (min reputation, required claim types).
    *   Global settings (e.g., minimum dispute period).
7.  **Modifiers:** Custom checks for gated access (`requiresMinReputation`, `requiresMinLevel`, `requiresClaimType`).
8.  **Internal Helper Functions:** For calculating reputation, checking level requirements, etc.
9.  **Public/External Functions (Minimum 20+):**
    *   **Admin/Setup (Ownable/Pausable):**
        *   Constructor
        *   Set claim type weights
        *   Set progression level reputation thresholds
        *   Add/Remove required claim types for a level
        *   Pause/Unpause contract
        *   Transfer admin role
    *   **Attestation Management:**
        *   `attest`: Create an attestation about another address.
        *   `revokeAttestation`: Attester revokes their own attestation.
        *   `disputeAttestation`: Subject disputes an attestation about them.
        *   `resolveDispute`: Admin resolves a disputed attestation.
        *   `getAttestation`: Retrieve a specific attestation by ID.
        *   `getAttestationsAbout`: Get all attestation IDs about a specific address.
        *   `getAttestationsByAttester`: Get all attestation IDs made by a specific address.
        *   `getAttestationsByTypeAbout`: Get attestation IDs of a specific type about an address.
    *   **Reputation & Progression (View/Pure):**
        *   `getUserReputation`: Calculate and return an address's current reputation score.
        *   `getUserProgressionLevel`: Calculate and return an address's current progression level.
        *   `checkProgressionLevelRequirements`: Check if an address meets the requirements for a *specific* level.
        *   `checkHasClaimOfType`: Check if an address has a non-revoked, non-disputed attestation of a specific type.
        *   `checkHasClaimWithValue`: Check if an address has a claim of a type with at least a certain value.
    *   **Gated/Conditional Access (Example Functions):**
        *   `accessReputationGatedFunction`: Example function requiring min reputation.
        *   `accessProgressionGatedFunction`: Example function requiring min progression level.
        *   `accessClaimGatedFunction`: Example function requiring a specific claim type/value.
        *   `triggerConditionalAction`: A more generic function that takes conditions and performs an action (like emitting an event or interacting with another contract, if integrated).
    *   **Utility/Views:**
        *   `getClaimTypeWeight`: Get the weight for a specific claim type.
        *   `getProgressionLevelThreshold`: Get the reputation threshold for a level.
        *   `getProgressionLevelRequiredClaims`: Get the required claims for a level.
        *   `getAttestationCounter`: Get the total number of attestations created.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the deployer as the admin.
2.  `setClaimTypeWeight(bytes32 _claimType, int256 _weight)`: Admin function to set the reputation weight for a specific claim type.
3.  `setProgressionLevelThreshold(uint256 _level, int256 _minReputation)`: Admin function to set the minimum reputation required to reach a specific progression level.
4.  `addProgressionLevelRequiredClaim(uint256 _level, bytes32 _claimType)`: Admin function to add a claim type that is required (in addition to reputation) to reach a specific progression level.
5.  `removeProgressionLevelRequiredClaim(uint256 _level, bytes32 _claimType)`: Admin function to remove a required claim type for a progression level.
6.  `pauseContract()`: Admin function to pause sensitive operations like attestation creation/resolution. Inherited from Pausable.
7.  `unpauseContract()`: Admin function to unpause the contract. Inherited from Pausable.
8.  `transferAdmin(address _newAdmin)`: Admin function to transfer ownership. Inherited from Ownable.
9.  `attest(address _about, bytes32 _claimType, int256 _value, uint64 _expirationTimestamp, bytes32 _dataHash)`: Allows any user to make an attestation about another user, specifying type, value, expiration, and a data hash for evidence. Requires contract not to be paused.
10. `revokeAttestation(uint256 _attestationId)`: Allows the original attester to revoke their previously made attestation.
11. `disputeAttestation(uint256 _attestationId)`: Allows the subject of an attestation (`_about` address) to mark it as disputed.
12. `resolveDispute(uint256 _attestationId, bool _isValid)`: Admin function to resolve a disputed attestation, marking it as either valid (undisputed) or effectively invalid (by potentially adjusting value or removing dispute flag with no value contribution). For simplicity here, setting `_isValid` to `false` might mean marking it revoked or just removing the dispute flag without value contribution. Let's just remove the dispute flag. A more complex system might require value adjustments.
13. `getAttestation(uint256 _attestationId)`: View function to retrieve the details of a specific attestation.
14. `getAttestationsAbout(address _about)`: View function to get an array of all attestation IDs made about a specific address.
15. `getAttestationsByAttester(address _attester)`: View function to get an array of all attestation IDs made by a specific address.
16. `getAttestationsByTypeAbout(address _about, bytes32 _claimType)`: View function to get attestation IDs of a specific type made about an address.
17. `getUserReputation(address _user)`: View function to calculate and return the current, dynamic reputation score for a user based on their valid attestations and claim weights. (Potential gas cost warning).
18. `getUserProgressionLevel(address _user)`: View function to calculate and return the highest progression level achieved by a user based on their reputation and required claims. (Potential gas cost warning).
19. `checkProgressionLevelRequirements(address _user, uint256 _level)`: View function to check if a user meets *all* criteria (reputation and required claims) for a specific level.
20. `checkHasClaimOfType(address _user, bytes32 _claimType)`: View function to check if a user has at least one non-revoked, non-disputed attestation of a specific type.
21. `checkHasClaimWithValue(address _user, bytes32 _claimType, int256 _minValue)`: View function to check if a user has at least one non-revoked, non-disputed attestation of a specific type with a value greater than or equal to `_minValue`.
22. `accessReputationGatedFunction(uint256 _requiredReputation)`: Example external function that can only be called by users with at least `_requiredReputation`. Emits an event if successful.
23. `accessProgressionGatedFunction(uint256 _requiredLevel)`: Example external function that can only be called by users who have reached at least `_requiredLevel`. Emits an event if successful.
24. `accessClaimGatedFunction(bytes32 _requiredClaimType, int256 _requiredValue)`: Example external function that can only be called by users who have a valid claim of type `_requiredClaimType` with at least `_requiredValue`. Emits an event if successful.
25. `triggerConditionalAction(address _user, uint256 _minReputation, uint256 _minLevel, bytes32[] memory _requiredClaimTypes)`: A more general example of a gated function. Requires the specified user (can be `msg.sender`) to meet *all* listed conditions (min rep, min level, existence of all required claim types) before performing a simple action (emitting an event).
26. `getClaimTypeWeight(bytes32 _claimType)`: View function to retrieve the weight of a specific claim type.
27. `getProgressionLevelThreshold(uint256 _level)`: View function to retrieve the minimum reputation threshold for a specific level.
28. `getProgressionLevelRequiredClaims(uint256 _level)`: View function to retrieve the array of required claim types for a specific level.
29. `getAttestationCounter()`: View function to get the total number of attestations created.
30. `isAdmin(address _addr)`: View function to check if an address is the current admin. Inherited from Ownable.

This system provides a flexible framework for building on-chain identity, reputation, and access control based on a network of verifiable claims, going beyond simple token gating or basic roles.

Here is the Solidity code implementing this concept:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Outline:
// 1. License & Pragma
// 2. Imports (Ownable, Pausable, SafeCast)
// 3. Contract Definition (inherits Ownable, Pausable)
// 4. Events
// 5. Structs (Attestation)
// 6. State Variables (Counters, Attestations storage, Mappings for lookup/reputation/config)
// 7. Modifiers (None explicitly custom, using Ownable/Pausable)
// 8. Internal Helper Functions (_calculateReputation, _getUserProgressionLevel, _check...)
// 9. Public/External Functions (Attestation Management, Configuration, Gated Access, Views)

// Function Summary:
// 1. constructor(): Initializes contract, sets deployer as admin.
// 2. setClaimTypeWeight(bytes32 _claimType, int256 _weight): Admin sets reputation weight for claim types.
// 3. setProgressionLevelThreshold(uint256 _level, int256 _minReputation): Admin sets min reputation for a level.
// 4. addProgressionLevelRequiredClaim(uint256 _level, bytes32 _claimType): Admin adds required claim type for a level.
// 5. removeProgressionLevelRequiredClaim(uint256 _level, bytes32 _claimType): Admin removes required claim type for a level.
// 6. pauseContract(): Admin pauses key functions. Inherited from Pausable.
// 7. unpauseContract(): Admin unpauses key functions. Inherited from Pausable.
// 8. transferAdmin(address _newAdmin): Admin transfers ownership. Inherited from Ownable.
// 9. attest(address _about, bytes32 _claimType, int256 _value, uint64 _expirationTimestamp, bytes32 _dataHash): Make an attestation about someone. Pausable.
// 10. revokeAttestation(uint256 _attestationId): Attester revokes their attestation.
// 11. disputeAttestation(uint256 _attestationId): Subject disputes attestation about them.
// 12. resolveDispute(uint256 _attestationId, bool _isValid): Admin resolves dispute (removes dispute flag).
// 13. getAttestation(uint256 _attestationId): View attestation details by ID.
// 14. getAttestationsAbout(address _about): View all attestation IDs about an address.
// 15. getAttestationsByAttester(address _attester): View all attestation IDs by an attester.
// 16. getAttestationsByTypeAbout(address _about, bytes32 _claimType): View attestation IDs of a specific type about an address.
// 17. getUserReputation(address _user): View user's dynamic reputation score. (Potentially gas heavy).
// 18. getUserProgressionLevel(address _user): View user's current progression level. (Potentially gas heavy).
// 19. checkProgressionLevelRequirements(address _user, uint256 _level): View if user meets all requirements for a specific level. (Potentially gas heavy).
// 20. checkHasClaimOfType(address _user, bytes32 _claimType): View if user has a valid claim of a type.
// 21. checkHasClaimWithValue(address _user, bytes32 _claimType, int256 _minValue): View if user has a valid claim of type with min value.
// 22. accessReputationGatedFunction(uint256 _requiredReputation): Example function requiring min reputation.
// 23. accessProgressionGatedFunction(uint256 _requiredLevel): Example function requiring min level.
// 24. accessClaimGatedFunction(bytes32 _requiredClaimType, int256 _requiredValue): Example function requiring specific claim type/value.
// 25. triggerConditionalAction(address _user, uint256 _minReputation, uint256 _minLevel, bytes32[] memory _requiredClaimTypes): General gated action based on multiple conditions for a user.
// 26. getClaimTypeWeight(bytes32 _claimType): View claim type weight.
// 27. getProgressionLevelThreshold(uint256 _level): View min reputation threshold for a level.
// 28. getProgressionLevelRequiredClaims(uint256 _level): View required claims for a level.
// 29. getAttestationCounter(): View total attestations count.
// 30. isAdmin(address _addr): View if address is admin. Inherited from Ownable.


contract VerifiableAttestationProgressiveAccess is Ownable, Pausable {
    using SafeCast for uint256;

    // --- Events ---
    event Attested(uint256 indexed attestationId, address indexed attester, address indexed about, bytes32 claimType, int256 value, uint64 expirationTimestamp, bytes32 dataHash);
    event AttestationRevoked(uint256 indexed attestationId, address indexed attester);
    event AttestationDisputed(uint256 indexed attestationId, address indexed disputer);
    event AttestationDisputeResolved(uint256 indexed attestationId, bool isValid);
    event ReputationUpdated(address indexed user, int256 newReputation); // Note: This event might not fire on every reputation change due to dynamic calculation
    event ProgressionLevelReached(address indexed user, uint256 level); // Note: This event might not fire every time level is reached due to dynamic calculation
    event ClaimTypeWeightSet(bytes32 indexed claimType, int256 weight);
    event ProgressionLevelThresholdSet(uint256 indexed level, int256 minReputation);
    event ProgressionLevelRequiredClaimAdded(uint256 indexed level, bytes32 claimType);
    event ProgressionLevelRequiredClaimRemoved(uint256 indexed level, bytes32 claimType);
    event GatedFunctionAccessed(address indexed user, string functionName, string conditionMet);
    event ConditionalActionTriggered(address indexed user, string conditionsDescription);

    // --- Structs ---
    struct Attestation {
        uint256 id;
        address attester;
        address about;
        bytes32 claimType;
        int256 value; // Could represent a score, count, or intensity
        uint64 timestamp;
        uint64 expirationTimestamp; // 0 means no expiration
        bytes32 dataHash; // Link to off-chain evidence (e.g., IPFS hash)
        bool revoked;
        bool disputed;
    }

    // --- State Variables ---
    uint256 private _attestationCounter;
    mapping(uint256 => Attestation) public attestations;
    mapping(address => uint256[]) private attestationIdsByAbout;
    mapping(address => uint256[]) private attestationIdsByAttester;

    // Note: Reputation is calculated dynamically in getUserReputation to avoid storing stale data,
    // but a cache mapping could be added for performance if recalculation is too heavy.
    // Mapping for claim type weights (how much an attestation of a type impacts reputation)
    mapping(bytes32 => int256) private _claimTypeWeights; // Default weight is 0 if not set

    // Mapping for progression level requirements
    mapping(uint256 => int256) private _progressionLevelThresholds; // level => min reputation required
    mapping(uint256 => bytes32[]) private _progressionLevelRequiredClaims; // level => array of required claim types

    // Keep track of maximum defined level for easier iteration
    uint256 private _maxProgressionLevel;

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) { // Start unpaused
        _attestationCounter = 0;
        // Example default weights (Admin can change)
        _claimTypeWeights[bytes32(0)] = 1; // Default empty type weight
        _claimTypeWeights["SkillVerified"] = 10;
        _claimTypeWeights["Achievement"] = 5;
        _claimTypeWeights["Association"] = 2;
        _claimTypeWeights["Warning"] = -20; // Negative value for negative impact
        _claimTypeWeights["VerifiedIdentity"] = 15;

        emit ClaimTypeWeightSet(bytes32(0), 1);
        emit ClaimTypeWeightSet("SkillVerified", 10);
        emit ClaimTypeWeightSet("Achievement", 5);
        emit ClaimTypeWeightSet("Association", 2);
        emit ClaimTypeWeightSet("Warning", -20);
        emit ClaimTypeWeightSet("VerifiedIdentity", 15);
    }

    // --- Admin/Setup Functions ---

    /// @notice Sets the reputation weight for a specific claim type. Only admin can call.
    /// @param _claimType The bytes32 identifier for the claim type.
    /// @param _weight The integer weight for this claim type (can be positive or negative).
    function setClaimTypeWeight(bytes32 _claimType, int256 _weight) external onlyOwner {
        _claimTypeWeights[_claimType] = _weight;
        emit ClaimTypeWeightSet(_claimType, _weight);
    }

    /// @notice Sets the minimum reputation required to reach a specific progression level. Only admin can call.
    /// @param _level The progression level number (starting from 1).
    /// @param _minReputation The minimum reputation score needed for this level.
    function setProgressionLevelThreshold(uint256 _level, int256 _minReputation) external onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        _progressionLevelThresholds[_level] = _minReputation;
        if (_level > _maxProgressionLevel) {
            _maxProgressionLevel = _level;
        }
        emit ProgressionLevelThresholdSet(_level, _minReputation);
    }

    /// @notice Adds a claim type that is required (in addition to reputation) to reach a specific progression level. Only admin can call.
    /// @param _level The progression level number.
    /// @param _claimType The bytes32 identifier for the required claim type.
    function addProgressionLevelRequiredClaim(uint256 _level, bytes32 _claimType) external onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        // Prevent adding duplicates (simple check, not exhaustive)
        for (uint256 i = 0; i < _progressionLevelRequiredClaims[_level].length; i++) {
            if (_progressionLevelRequiredClaims[_level][i] == _claimType) {
                return; // Already exists
            }
        }
        _progressionLevelRequiredClaims[_level].push(_claimType);
        emit ProgressionLevelRequiredClaimAdded(_level, _claimType);
    }

    /// @notice Removes a required claim type for a specific progression level. Only admin can call.
    /// @param _level The progression level number.
    /// @param _claimType The bytes32 identifier for the required claim type to remove.
    function removeProgressionLevelRequiredClaim(uint256 _level, bytes32 _claimType) external onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        bytes32[] storage requiredClaims = _progressionLevelRequiredClaims[_level];
        for (uint256 i = 0; i < requiredClaims.length; i++) {
            if (requiredClaims[i] == _claimType) {
                // Swap with last element and pop
                requiredClaims[i] = requiredClaims[requiredClaims.length - 1];
                requiredClaims.pop();
                emit ProgressionLevelRequiredClaimRemoved(_level, _claimType);
                return;
            }
        }
        // Revert if claim type not found? Or just do nothing? Let's just do nothing.
    }

    /// @notice Pauses the contract. Inherited from Pausable.
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract. Inherited from Pausable.
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership is inherited from Ownable and made external by default.

    // --- Attestation Management Functions ---

    /// @notice Creates a new attestation about a user. Callable by any address when not paused.
    /// @param _about The address the attestation is about.
    /// @param _claimType The bytes32 identifier of the claim type.
    /// @param _value The integer value associated with the claim (can be positive or negative).
    /// @param _expirationTimestamp The Unix timestamp when the attestation expires (0 for no expiration).
    /// @param _dataHash A bytes32 hash linking to off-chain evidence.
    function attest(
        address _about,
        bytes32 _claimType,
        int256 _value,
        uint64 _expirationTimestamp,
        bytes32 _dataHash
    ) external whenNotPaused {
        require(_about != address(0), "Cannot attest about zero address");
        require(_about != msg.sender, "Cannot attest about self directly"); // Discourage self-attestation, can be relaxed if needed

        _attestationCounter++;
        uint256 attestationId = _attestationCounter;
        uint64 currentTimestamp = uint64(block.timestamp);

        attestations[attestationId] = Attestation({
            id: attestationId,
            attester: msg.sender,
            about: _about,
            claimType: _claimType,
            value: _value,
            timestamp: currentTimestamp,
            expirationTimestamp: _expirationTimestamp,
            dataHash: _dataHash,
            revoked: false,
            disputed: false
        });

        attestationIdsByAbout[_about].push(attestationId);
        attestationIdsByAttester[msg.sender].push(attestationId);

        emit Attested(attestationId, msg.sender, _about, _claimType, _value, _expirationTimestamp, _dataHash);

        // Note: Reputation is not updated immediately here due to dynamic calculation
    }

    /// @notice Revokes a previously made attestation. Only the original attester can call this.
    /// @param _attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 _attestationId) external {
        require(_attestationId > 0 && _attestationId <= _attestationCounter, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(!att.revoked, "Attestation already revoked");
        require(!att.disputed, "Cannot revoke disputed attestation"); // Prevent revocation during dispute
        require(att.attester == msg.sender, "Only attester can revoke");

        att.revoked = true;

        emit AttestationRevoked(_attestationId, msg.sender);
        // Note: Reputation is not updated immediately here
    }

    /// @notice Marks an attestation as disputed by the subject of the attestation.
    /// @param _attestationId The ID of the attestation to dispute.
    function disputeAttestation(uint256 _attestationId) external {
        require(_attestationId > 0 && _attestationId <= _attestationCounter, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(!att.revoked, "Cannot dispute revoked attestation");
        require(!att.disputed, "Attestation already disputed");
        require(att.about == msg.sender, "Only subject of attestation can dispute");

        att.disputed = true;

        emit AttestationDisputed(_attestationId, msg.sender);
        // Note: Reputation is not updated immediately here
    }

    /// @notice Resolves a disputed attestation. Only admin can call.
    /// @param _attestationId The ID of the disputed attestation.
    /// @param _isValid True if the attestation is deemed valid, false otherwise (effectively removes its impact).
    function resolveDispute(uint256 _attestationId, bool _isValid) external onlyOwner {
        require(_attestationId > 0 && _attestationId <= _attestationCounter, "Invalid attestation ID");
        Attestation storage att = attestations[_attestationId];
        require(att.disputed, "Attestation is not disputed");

        att.disputed = false; // Remove the disputed flag

        if (!_isValid) {
             // If deemed invalid, effectively remove its impact by marking it revoked
             att.revoked = true;
        }

        emit AttestationDisputeResolved(_attestationId, _isValid);
        // Note: Reputation is not updated immediately here
    }

    /// @notice Gets the details of a specific attestation.
    /// @param _attestationId The ID of the attestation.
    /// @return The Attestation struct details.
    function getAttestation(uint256 _attestationId) external view returns (Attestation memory) {
        require(_attestationId > 0 && _attestationId <= _attestationCounter, "Invalid attestation ID");
        return attestations[_attestationId];
    }

    /// @notice Gets the IDs of all attestations made about a specific address.
    /// @param _about The address to query about.
    /// @return An array of attestation IDs.
    function getAttestationsAbout(address _about) external view returns (uint256[] memory) {
        return attestationIdsByAbout[_about];
    }

     /// @notice Gets the IDs of all attestations made by a specific address.
    /// @param _attester The address to query by.
    /// @return An array of attestation IDs.
    function getAttestationsByAttester(address _attester) external view returns (uint256[] memory) {
        return attestationIdsByAttester[_attester];
    }

    /// @notice Gets the IDs of attestations of a specific type made about an address.
    /// @param _about The address to query about.
    /// @param _claimType The type of claim to filter by.
    /// @return An array of attestation IDs.
    function getAttestationsByTypeAbout(address _about, bytes32 _claimType) external view returns (uint256[] memory) {
        uint256[] memory allAboutIds = attestationIdsByAbout[_about];
        uint256[] memory filteredIds = new uint256[](allAboutIds.length); // Max possible size
        uint256 filterCount = 0;

        for (uint256 i = 0; i < allAboutIds.length; i++) {
            uint256 attId = allAboutIds[i];
            if (attestations[attId].claimType == _claimType) {
                filteredIds[filterCount] = attId;
                filterCount++;
            }
        }

        bytes memory packed = abi.encodePacked(filteredIds); // Pack to get dynamic size
        return abi.decode(packed[0:filterCount * 32], (uint256[])); // Decode back to correctly sized array
    }


    // --- Reputation & Progression View Functions ---

    /// @notice Calculates and returns the current, dynamic reputation score for a user.
    /// @param _user The address of the user.
    /// @return The calculated reputation score (int256).
    /// @dev WARNING: This function iterates through all non-revoked/non-disputed attestations for a user.
    /// It can be gas-intensive if a user has a very large number of attestations.
    function getUserReputation(address _user) public view returns (int256) {
        int256 reputation = 0;
        uint256 currentTimestamp = block.timestamp;
        uint256[] memory userAttestationIds = attestationIdsByAbout[_user];

        for (uint256 i = 0; i < userAttestationIds.length; i++) {
            uint256 attId = userAttestationIds[i];
            Attestation storage att = attestations[attId];

            // Only consider valid, non-expired, non-revoked, non-disputed attestations
            if (!att.revoked && !att.disputed && (att.expirationTimestamp == 0 || att.expirationTimestamp > currentTimestamp)) {
                int256 weight = _claimTypeWeights[att.claimType];
                // Add the value multiplied by the weight. Careful with overflow if using large values/weights
                reputation += (att.value * weight);
            }
        }
        return reputation;
    }

    /// @notice Calculates and returns the highest progression level achieved by a user.
    /// @param _user The address of the user.
    /// @return The highest progression level reached (uint256). Returns 0 if no levels are met.
    /// @dev WARNING: This function calculates reputation and checks requirements for defined levels.
    /// Can be gas-intensive depending on the number of defined levels and attestations.
    function getUserProgressionLevel(address _user) public view returns (uint256) {
        int256 currentReputation = getUserReputation(_user);
        uint256 highestLevel = 0;

        // Iterate downwards from max level to find the highest level met
        for (uint256 level = _maxProgressionLevel; level > 0; level--) {
            if (checkProgressionLevelRequirements(_user, level)) {
                highestLevel = level;
                break; // Found the highest level
            }
        }
        return highestLevel;
    }

     /// @notice Checks if a user meets *all* criteria for a specific progression level.
    /// @param _user The address of the user.
    /// @param _level The progression level to check.
    /// @return True if the user meets all requirements for the level, false otherwise.
     function checkProgressionLevelRequirements(address _user, uint256 _level) public view returns (bool) {
        if (_level == 0 || _level > _maxProgressionLevel) {
            return false; // Level 0 doesn't exist, level must be defined
        }

        int256 requiredReputation = _progressionLevelThresholds[_level];
        int256 currentUserReputation = getUserReputation(_user);

        // Check reputation threshold first
        if (currentUserReputation < requiredReputation) {
            return false;
        }

        // Check required claim types
        bytes32[] memory requiredClaims = _progressionLevelRequiredClaims[_level];
        for (uint256 i = 0; i < requiredClaims.length; i++) {
            // Check if the user has *any* valid attestation of this required type
            if (!checkHasClaimOfType(_user, requiredClaims[i])) {
                 return false;
            }
            // Note: Could add a requirement for minimum value on these claims here if needed
        }

        // If all checks pass
        return true;
    }

    /// @notice Checks if a user has at least one valid (non-revoked, non-disputed, non-expired) attestation of a specific type.
    /// @param _user The address of the user.
    /// @param _claimType The claim type to check for.
    /// @return True if the user has a matching valid claim, false otherwise.
    function checkHasClaimOfType(address _user, bytes32 _claimType) public view returns (bool) {
         uint256 currentTimestamp = block.timestamp;
         uint256[] memory userAttestationIds = attestationIdsByAbout[_user];

         for (uint256 i = 0; i < userAttestationIds.length; i++) {
             uint256 attId = userAttestationIds[i];
             Attestation storage att = attestations[attId];

             if (att.claimType == _claimType && !att.revoked && !att.disputed && (att.expirationTimestamp == 0 || att.expirationTimestamp > currentTimestamp)) {
                 return true; // Found a valid claim of the required type
             }
         }
         return false; // No valid claim of this type found
    }

     /// @notice Checks if a user has at least one valid attestation of a specific type with a value >= minimum value.
    /// @param _user The address of the user.
    /// @param _claimType The claim type to check for.
    /// @param _minValue The minimum value the claim must have.
    /// @return True if the user has a matching valid claim with sufficient value, false otherwise.
    function checkHasClaimWithValue(address _user, bytes32 _claimType, int256 _minValue) public view returns (bool) {
         uint256 currentTimestamp = block.timestamp;
         uint256[] memory userAttestationIds = attestationIdsByAbout[_user];

         for (uint256 i = 0; i < userAttestationIds.length; i++) {
             uint256 attId = userAttestationIds[i];
             Attestation storage att = attestations[attId];

             if (att.claimType == _claimType && att.value >= _minValue && !att.revoked && !att.disputed && (att.expirationTimestamp == 0 || att.expirationTimestamp > currentTimestamp)) {
                 return true; // Found a valid claim of the required type with sufficient value
             }
         }
         return false; // No valid claim of this type with sufficient value found
    }


    // --- Gated/Conditional Access Example Functions ---
    // These functions demonstrate how the checks can be used to gate access

    /// @notice Example function that requires the caller to have a minimum reputation score.
    /// @param _requiredReputation The minimum reputation score needed to call this function.
    function accessReputationGatedFunction(uint256 _requiredReputation) external view whenNotPaused {
        require(getUserReputation(msg.sender) >= _requiredReputation.toInt256(), "Insufficient reputation");
        // --- Gated Action Here ---
        emit GatedFunctionAccessed(msg.sender, "accessReputationGatedFunction", string(abi.encodePacked("Min Reputation: ", _requiredReputation)));
        // This is where you would put the logic only authorized users can access
    }

    /// @notice Example function that requires the caller to have reached a minimum progression level.
    /// @param _requiredLevel The minimum progression level needed to call this function.
     function accessProgressionGatedFunction(uint256 _requiredLevel) external view whenNotPaused {
        require(getUserProgressionLevel(msg.sender) >= _requiredLevel, "Insufficient progression level");
        // --- Gated Action Here ---
        emit GatedFunctionAccessed(msg.sender, "accessProgressionGatedFunction", string(abi.encodePacked("Min Level: ", _requiredLevel)));
        // This is where you would put the logic only authorized users can access
    }

    /// @notice Example function that requires the caller to have a valid attestation of a specific type with a minimum value.
    /// @param _requiredClaimType The required claim type.
    /// @param _requiredValue The minimum value for that claim type.
    function accessClaimGatedFunction(bytes32 _requiredClaimType, int256 _requiredValue) external view whenNotPaused {
        require(checkHasClaimWithValue(msg.sender, _requiredClaimType, _requiredValue), "Required claim not found or insufficient value");
        // --- Gated Action Here ---
        emit GatedFunctionAccessed(msg.sender, "accessClaimGatedFunction", string(abi.encodePacked("Claim Type: ", string(abi.encode(_requiredClaimType)), ", Min Value: ", _requiredValue)));
        // This is where you would put the logic only authorized users can access
    }

    /// @notice A more general example function that requires a user (could be caller or another address)
    /// to meet multiple conditions simultaneously before triggering an action.
    /// @param _user The address to check conditions for.
    /// @param _minReputation The minimum reputation required.
    /// @param _minLevel The minimum progression level required.
    /// @param _requiredClaimTypes An array of claim types that the user must possess.
    function triggerConditionalAction(
        address _user,
        uint256 _minReputation,
        uint256 _minLevel,
        bytes32[] memory _requiredClaimTypes
    ) external whenNotPaused {
        // Check Reputation
        require(getUserReputation(_user) >= _minReputation.toInt256(), "User does not meet minimum reputation");

        // Check Progression Level
        require(getUserProgressionLevel(_user) >= _minLevel, "User does not meet minimum progression level");

        // Check Required Claim Types
        for (uint256 i = 0; i < _requiredClaimTypes.length; i++) {
            require(checkHasClaimOfType(_user, _requiredClaimTypes[i]), string(abi.encodePacked("User missing required claim type: ", string(abi.encode(_requiredClaimTypes[i])))));
        }

        // --- Conditional Action Here ---
        // This is where the actual action requiring these conditions would be performed.
        // For this example, we just emit an event.
        emit ConditionalActionTriggered(_user, "Met combined reputation, level, and claim requirements");
    }

    // --- Utility and View Functions ---

    /// @notice Gets the current reputation weight for a specific claim type.
    /// @param _claimType The bytes32 identifier for the claim type.
    /// @return The integer weight.
    function getClaimTypeWeight(bytes32 _claimType) external view returns (int256) {
        return _claimTypeWeights[_claimType];
    }

    /// @notice Gets the minimum reputation threshold for a specific progression level.
    /// @param _level The progression level number.
    /// @return The minimum reputation score.
    function getProgressionLevelThreshold(uint256 _level) external view returns (int256) {
        require(_level > 0, "Level must be greater than 0");
        return _progressionLevelThresholds[_level];
    }

     /// @notice Gets the array of required claim types for a specific progression level.
    /// @param _level The progression level number.
    /// @return An array of bytes32 claim types.
    function getProgressionLevelRequiredClaims(uint256 _level) external view returns (bytes32[] memory) {
         require(_level > 0, "Level must be greater than 0");
         return _progressionLevelRequiredClaims[_level];
    }

    /// @notice Gets the total number of attestations created.
    /// @return The attestation counter value.
    function getAttestationCounter() external view returns (uint256) {
        return _attestationCounter;
    }

    /// @notice Checks if an address is the current contract admin. Inherited from Ownable.
    function isAdmin(address _addr) external view returns (bool) {
        return owner() == _addr;
    }
}
```