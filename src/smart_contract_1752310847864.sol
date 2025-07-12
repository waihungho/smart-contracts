Okay, let's design a smart contract focused on **Decentralized Attestation and Reputation Building**. It acts as a core layer where users can create profiles, receive verifiable attestations from others (or trusted entities), and build a reputation score based on these attestations. Other contracts or dApps can then query this contract to verify identities, check attestations, and leverage reputation for various purposes (e.g., access control, weighted voting, tiered benefits).

This concept is creative as it builds a general-purpose attestation layer; advanced by linking dynamic reputation to attestations; trendy as it taps into decentralized identity (DID) and verifiable credentials concepts adapted for Solidity. It's not a direct clone of existing standard tokens or DAOs, though it uses common patterns like role-based access control and structs/mappings.

Here's the contract outline and summary, followed by the Solidity code:

---

**Contract: AetherProfile**

**Concept:** A decentralized protocol for creating profiles, issuing and managing attestations, and calculating a dynamic reputation score based on these attestations. It serves as a public, on-chain identity and trust layer.

**Outline:**

1.  **State Variables:**
    *   Counters for Profile IDs, Attestation Type IDs, and Attestation IDs.
    *   Mappings for storing Profiles, Attestation Types, and Attestations.
    *   Mappings for tracking profile owners and attestation ownership/revocation.
    *   Arrays/Mappings for role-based access control (Owner, Admins, Attestation Type Managers).
    *   Configuration variables (e.g., base URIs).
2.  **Structs:**
    *   `Profile`: Represents a user's on-chain profile.
    *   `AttestationType`: Defines categories of attestations and their impact.
    *   `Attestation`: Represents a single issued attestation.
3.  **Events:** Signalling key state changes (profile creation, attestation submission, role changes, etc.).
4.  **Modifiers:** Restricting function access based on roles or conditions.
5.  **Role Management Functions:** Adding/removing administrators and attestation type managers.
6.  **Configuration Functions:** Setting base URIs and other contract-level parameters.
7.  **Profile Management Functions:** Creating, updating, and retrieving user profiles.
8.  **Attestation Type Management Functions:** Creating, updating, and retrieving types of attestations.
9.  **Attestation Management Functions:** Submitting, revoking, and retrieving individual attestations.
10. **Reputation & Query Functions:** Calculating/retrieving reputation scores, checking specific attestations, and retrieving lists of attestations.
11. **Utility/View Functions:** Getting total counts, checking ownership, etc.

**Function Summary:**

**Role Management:**
*   `addAdmin(address newAdmin)`: Grants admin role (Owner only).
*   `removeAdmin(address admin)`: Revokes admin role (Owner only).
*   `isAdmin(address candidate)`: Checks if address is an admin (View).
*   `addAttestationTypeManager(address manager)`: Grants attestation type manager role (Admin only).
*   `removeAttestationTypeManager(address manager)`: Revokes attestation type manager role (Admin only).
*   `isAttestationTypeManager(address candidate)`: Checks if address is an attestation type manager (View).

**Configuration:**
*   `setContractURI(string uri)`: Sets a URI for contract-level metadata (Owner only).
*   `getContractURI()`: Gets the contract metadata URI (View).
*   `setBaseAttestationMetadataURI(string uri)`: Sets a base URI for attestation metadata (Admin only).
*   `getBaseAttestationMetadataURI()`: Gets the base attestation metadata URI (View).

**Profile Management:**
*   `createProfile(string name, string profileURI)`: Creates a new user profile for the caller.
*   `updateProfileURI(uint256 profileId, string newURI)`: Updates the profile metadata URI (Profile Owner only).
*   `updateProfileName(uint256 profileId, string newName)`: Updates the profile name (Profile Owner only).
*   `getProfile(uint256 profileId)`: Retrieves details of a profile (View).
*   `getProfileIdByOwner(address owner)`: Gets the profile ID associated with an address (View).
*   `getTotalProfiles()`: Gets the total number of created profiles (View).

**Attestation Type Management:**
*   `createAttestationType(string name, int256 reputationImpact, bool requiresVerification)`: Creates a new category of attestation (Admin or Attestation Type Manager only).
*   `updateAttestationType(uint256 typeId, string name, int256 reputationImpact, bool requiresVerification)`: Updates details of an attestation type (Admin or Attestation Type Manager only).
*   `getAttestationType(uint256 typeId)`: Retrieves details of an attestation type (View).
*   `getTotalAttestationTypes()`: Gets the total number of attestation types (View).

**Attestation Management:**
*   `submitAttestation(uint256 profileId, uint256 attestationTypeId, string metadataURI)`: Issues an attestation for a profile. Updates the profile's reputation.
*   `revokeAttestation(uint256 attestationId)`: Revokes an attestation. Reverts the reputation impact (Attester or Admin only).
*   `getAttestation(uint256 attestationId)`: Retrieves details of a specific attestation (View).
*   `getAttestationsByProfileId(uint256 profileId)`: Gets a list of attestation IDs for a profile (View).
*   `getAttestationsByAttester(address attester)`: Gets a list of attestation IDs issued by an address (View).
*   `getTotalAttestations()`: Gets the total number of submitted attestations (View).
*   `getAttestationCountByType(uint256 attestationTypeId)`: Gets the total count of attestations for a specific type (View).

**Reputation & Query:**
*   `getProfileReputation(uint256 profileId)`: Retrieves the current reputation score for a profile (View).
*   `hasAttestationTypeForProfile(uint256 profileId, uint256 attestationTypeId)`: Checks if a profile has at least one active attestation of a specific type (View).
*   `getAttestationCountForTypeForProfile(uint256 profileId, uint256 attestationTypeId)`: Gets the count of active attestations of a specific type for a profile (View).
*   `isAttestationActive(uint256 attestationId)`: Checks if a specific attestation is currently active (View).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contract: AetherProfile
// Concept: A decentralized protocol for creating profiles, issuing and managing attestations,
// and calculating a dynamic reputation score based on these attestations.
// It serves as a public, on-chain identity and trust layer for dApps and protocols.

// Outline:
// 1. State Variables: Counters, Mappings for data, Role tracking, Config
// 2. Structs: Profile, AttestationType, Attestation
// 3. Events: Signalling state changes
// 4. Modifiers: Access control checks
// 5. Role Management: Admin and Attestation Type Manager roles
// 6. Configuration: Contract & metadata URIs
// 7. Profile Management: Create, update, get profiles
// 8. Attestation Type Management: Create, update, get attestation types
// 9. Attestation Management: Submit, revoke, get attestations by ID/profile/attester
// 10. Reputation & Query: Get reputation, check specific attestations, get counts
// 11. Utility Views: Total counts, ownership checks

contract AetherProfile {

    // --- State Variables ---

    address public owner;
    uint256 private _nextProfileId = 1;
    uint256 private _nextAttestationTypeId = 1;
    uint256 private _nextAttestationId = 1;

    // Data Storage
    mapping(uint256 => Profile) public profiles;
    mapping(address => uint256) public profileIdByOwner; // Allows O(1) lookup for a user's profile ID
    mapping(uint256 => AttestationType) public attestationTypes;
    mapping(uint256 => Attestation) public attestations;

    // Indexing for retrieval (simplistic, gas considerations apply for very large sets)
    mapping(uint256 => uint256[]) private profileAttestationIds; // Profile ID -> list of attestation IDs
    mapping(address => uint256[]) private attesterAttestationIds; // Attester Address -> list of attestation IDs

    // Role-Based Access Control
    mapping(address => bool) public admins;
    mapping(address => bool) public attestationTypeManagers;

    // Configuration
    string public contractURI; // ERC-165 compatible metadata URI for the contract itself
    string public baseAttestationMetadataURI; // Base URI for attestation metadata (optional helper)

    // --- Structs ---

    struct Profile {
        uint256 id;
        address owner;
        string name;
        string profileURI; // URI pointing to off-chain metadata (e.g., JSON file)
        int256 reputationScore; // Sum of active attestation impacts
        uint256 totalAttestationsReceived; // Total number of active attestations received
        bool isInitialized; // Flag to check if profile exists
    }

    struct AttestationType {
        uint256 id;
        string name;
        int256 reputationImpact; // Amount added/subtracted from reputation score
        bool requiresVerification; // If true, attestation might require manual verification by an admin (not enforced by contract logic, just a flag)
        bool exists; // Flag to check if type exists
    }

    struct Attestation {
        uint256 id;
        uint256 profileId; // Profile being attested to
        address attester; // Address issuing the attestation
        uint256 attestationTypeId; // Type of attestation (e.g., "Skill", "Endorsement")
        string metadataURI; // URI pointing to off-chain attestation details
        uint256 timestamp;
        bool isActive; // Can be set to false if revoked
        bool exists; // Flag to check if attestation exists
    }

    // --- Events ---

    event ProfileCreated(uint256 indexed profileId, address indexed owner, string name, string profileURI);
    event ProfileUpdated(uint256 indexed profileId, string newName, string newProfileURI);
    event AttestationTypeCreated(uint256 indexed typeId, string name, int256 reputationImpact);
    event AttestationTypeUpdated(uint256 indexed typeId, string name, int256 reputationImpact);
    event AttestationSubmitted(uint256 indexed attestationId, uint256 indexed profileId, uint256 indexed attestationTypeId, address attester, int256 reputationChange);
    event AttestationRevoked(uint256 indexed attestationId, uint256 indexed profileId, int256 reputationChange);
    event ReputationUpdated(uint256 indexed profileId, int256 newReputationScore);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event AttestationTypeManagerAdded(address indexed manager);
    event AttestationTypeManagerRemoved(address indexed manager);
    event ContractURIUpdated(string uri);
    event BaseAttestationMetadataURIUpdated(string uri);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "Not admin");
        _;
    }

    modifier onlyAttestationTypeManager() {
        require(attestationTypeManagers[msg.sender] || admins[msg.sender] || msg.sender == owner, "Not attestation type manager or admin");
        _;
    }

    modifier onlyProfileOwner(uint256 _profileId) {
        require(profiles[_profileId].owner == msg.sender, "Not profile owner");
        _;
    }

    modifier onlyAttesterOrAdmin(uint256 _attestationId) {
        require(attestations[_attestationId].attester == msg.sender || admins[msg.sender] || msg.sender == owner, "Not attester or admin");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Role Management ---

    /// @notice Grants the admin role to an address.
    /// @param newAdmin The address to grant the role to.
    function addAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Invalid address");
        require(!admins[newAdmin], "Address is already an admin");
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    /// @notice Revokes the admin role from an address.
    /// @param admin The address to revoke the role from.
    function removeAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        require(admins[admin], "Address is not an admin");
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    /// @notice Checks if an address is an admin.
    /// @param candidate The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address candidate) external view returns (bool) {
        return admins[candidate] || candidate == owner;
    }

    /// @notice Grants the attestation type manager role to an address.
    /// @param manager The address to grant the role to.
    function addAttestationTypeManager(address manager) external onlyAdmin {
        require(manager != address(0), "Invalid address");
        require(!attestationTypeManagers[manager], "Address is already an attestation type manager");
        attestationTypeManagers[manager] = true;
        emit AttestationTypeManagerAdded(manager);
    }

    /// @notice Revokes the attestation type manager role from an address.
    /// @param manager The address to revoke the role from.
    function removeAttestationTypeManager(address manager) external onlyAdmin {
        require(manager != address(0), "Invalid address");
        require(attestationTypeManagers[manager], "Address is not an attestation type manager");
        attestationTypeManagers[manager] = false;
        emit AttestationTypeManagerRemoved(manager);
    }

    /// @notice Checks if an address is an attestation type manager.
    /// @param candidate The address to check.
    /// @return True if the address is an attestation type manager, false otherwise.
    function isAttestationTypeManager(address candidate) external view returns (bool) {
        return attestationTypeManagers[candidate] || admins[candidate] || candidate == owner;
    }

    // --- Configuration ---

    /// @notice Sets a URI for contract-level metadata.
    /// @param uri The URI string.
    function setContractURI(string memory uri) external onlyOwner {
        contractURI = uri;
        emit ContractURIUpdated(uri);
    }

    /// @notice Gets the contract metadata URI.
    /// @return The contract metadata URI.
    function getContractURI() external view returns (string memory) {
        return contractURI;
    }

    /// @notice Sets a base URI for attestation metadata.
    /// @param uri The base URI string.
    function setBaseAttestationMetadataURI(string memory uri) external onlyAdmin {
        baseAttestationMetadataURI = uri;
        emit BaseAttestationMetadataURIUpdated(uri);
    }

    /// @notice Gets the base attestation metadata URI.
    /// @return The base attestation metadata URI.
    function getBaseAttestationMetadataURI() external view returns (string memory) {
        return baseAttestationMetadataURI;
    }

    // --- Profile Management ---

    /// @notice Creates a new user profile for the caller.
    /// @param name The name for the profile.
    /// @param profileURI The URI pointing to the profile's metadata.
    /// @return The ID of the newly created profile.
    function createProfile(string memory name, string memory profileURI) external returns (uint256) {
        require(profileIdByOwner[msg.sender] == 0, "Profile already exists for this address");

        uint256 newProfileId = _nextProfileId++;
        profiles[newProfileId] = Profile({
            id: newProfileId,
            owner: msg.sender,
            name: name,
            profileURI: profileURI,
            reputationScore: 0,
            totalAttestationsReceived: 0,
            isInitialized: true
        });
        profileIdByOwner[msg.sender] = newProfileId;

        emit ProfileCreated(newProfileId, msg.sender, name, profileURI);
        return newProfileId;
    }

    /// @notice Updates the profile metadata URI.
    /// @param profileId The ID of the profile to update.
    /// @param newURI The new URI.
    function updateProfileURI(uint256 profileId, string memory newURI) external onlyProfileOwner(profileId) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        profiles[profileId].profileURI = newURI;
        emit ProfileUpdated(profileId, profiles[profileId].name, newURI);
    }

    /// @notice Updates the profile name.
    /// @param profileId The ID of the profile to update.
    /// @param newName The new name.
    function updateProfileName(uint256 profileId, string memory newName) external onlyProfileOwner(profileId) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        profiles[profileId].name = newName;
        emit ProfileUpdated(profileId, newName, profiles[profileId].profileURI);
    }

    /// @notice Retrieves details of a profile.
    /// @param profileId The ID of the profile.
    /// @return profile The Profile struct.
    function getProfile(uint256 profileId) external view returns (Profile memory) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        return profiles[profileId];
    }

    /// @notice Gets the profile ID associated with an address.
    /// @param owner The address.
    /// @return The profile ID (0 if no profile exists).
    function getProfileIdByOwner(address owner) external view returns (uint256) {
        return profileIdByOwner[owner];
    }

    /// @notice Gets the total number of created profiles.
    /// @return The total number of profiles.
    function getTotalProfiles() external view returns (uint256) {
        return _nextProfileId - 1;
    }

    // --- Attestation Type Management ---

    /// @notice Creates a new category of attestation.
    /// @param name The name of the attestation type.
    /// @param reputationImpact The amount reputation changes when this attestation is active.
    /// @param requiresVerification Flag indicating if this type typically needs verification.
    /// @return The ID of the new attestation type.
    function createAttestationType(string memory name, int256 reputationImpact, bool requiresVerification) external onlyAttestationTypeManager {
        uint256 newTypeId = _nextAttestationTypeId++;
        attestationTypes[newTypeId] = AttestationType({
            id: newTypeId,
            name: name,
            reputationImpact: reputationImpact,
            requiresVerification: requiresVerification,
            exists: true
        });
        emit AttestationTypeCreated(newTypeId, name, reputationImpact);
        return newTypeId;
    }

    /// @notice Updates details of an attestation type.
    /// @param typeId The ID of the attestation type to update.
    /// @param name The new name.
    /// @param reputationImpact The new reputation impact.
    /// @param requiresVerification The new requires verification flag.
    function updateAttestationType(uint256 typeId, string memory name, int256 reputationImpact, bool requiresVerification) external onlyAttestationTypeManager {
        require(attestationTypes[typeId].exists, "Attestation type does not exist");
        attestationTypes[typeId].name = name;
        attestationTypes[typeId].reputationImpact = reputationImpact;
        attestationTypes[typeId].requiresVerification = requiresVerification;
        emit AttestationTypeUpdated(typeId, name, reputationImpact);
        // Note: Updating reputation impact *does not* retroactively change existing reputations.
        // A more complex system could re-calculate, but that's gas-intensive.
    }

    /// @notice Retrieves details of an attestation type.
    /// @param typeId The ID of the attestation type.
    /// @return typeData The AttestationType struct.
    function getAttestationType(uint256 typeId) external view returns (AttestationType memory) {
        require(attestationTypes[typeId].exists, "Attestation type does not exist");
        return attestationTypes[typeId];
    }

    /// @notice Gets the total number of attestation types.
    /// @return The total number of attestation types.
    function getTotalAttestationTypes() external view returns (uint256) {
        return _nextAttestationTypeId - 1;
    }

    // --- Attestation Management ---

    /// @notice Issues an attestation for a profile. Updates the profile's reputation.
    /// @param profileId The ID of the profile being attested to.
    /// @param attestationTypeId The ID of the attestation type.
    /// @param metadataURI The URI pointing to off-chain attestation details.
    /// @return The ID of the newly created attestation.
    function submitAttestation(uint256 profileId, uint256 attestationTypeId, string memory metadataURI) external returns (uint256) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        require(attestationTypes[attestationTypeId].exists, "Attestation type does not exist");
        // Prevent self-attestation if desired (can be added here)
        // require(profiles[profileId].owner != msg.sender, "Cannot attest to yourself");

        uint256 newAttestationId = _nextAttestationId++;
        AttestationType storage aType = attestationTypes[attestationTypeId];

        attestations[newAttestationId] = Attestation({
            id: newAttestationId,
            profileId: profileId,
            attester: msg.sender,
            attestationTypeId: attestationTypeId,
            metadataURI: metadataURI,
            timestamp: block.timestamp,
            isActive: true, // Starts active
            exists: true
        });

        // Update profile state
        profiles[profileId].reputationScore += aType.reputationImpact;
        profiles[profileId].totalAttestationsReceived++;

        // Update indexes
        profileAttestationIds[profileId].push(newAttestationId);
        attesterAttestationIds[msg.sender].push(newAttestationId);

        emit AttestationSubmitted(newAttestationId, profileId, attestationTypeId, msg.sender, aType.reputationImpact);
        emit ReputationUpdated(profileId, profiles[profileId].reputationScore);

        return newAttestationId;
    }

    /// @notice Revokes an attestation. Reverts the reputation impact.
    /// Can only be called by the original attester or an admin/owner.
    /// @param attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 attestationId) external onlyAttesterOrAdmin(attestationId) {
        require(attestations[attestationId].exists, "Attestation does not exist");
        require(attestations[attestationId].isActive, "Attestation is already inactive");

        Attestation storage att = attestations[attestationId];
        AttestationType storage aType = attestationTypes[att.attestationTypeId];
        Profile storage profile = profiles[att.profileId];

        att.isActive = false;

        // Revert reputation impact
        profile.reputationScore -= aType.reputationImpact; // Subtract the amount that was added
        profile.totalAttestationsReceived--;

        emit AttestationRevoked(attestationId, att.profileId, aType.reputationImpact);
        emit ReputationUpdated(att.profileId, profile.reputationScore);
    }

    /// @notice Retrieves details of a specific attestation.
    /// @param attestationId The ID of the attestation.
    /// @return attestation The Attestation struct.
    function getAttestation(uint256 attestationId) external view returns (Attestation memory) {
        require(attestations[attestationId].exists, "Attestation does not exist");
        return attestations[attestationId];
    }

    /// @notice Gets a list of attestation IDs for a profile.
    /// @param profileId The ID of the profile.
    /// @return An array of attestation IDs.
    function getAttestationsByProfileId(uint256 profileId) external view returns (uint256[] memory) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        return profileAttestationIds[profileId];
    }

    /// @notice Gets a list of attestation IDs issued by an address.
    /// @param attester The address of the attester.
    /// @return An array of attestation IDs.
    function getAttestationsByAttester(address attester) external view returns (uint256[] memory) {
        return attesterAttestationIds[attester];
    }

     /// @notice Gets the total number of submitted attestations (including inactive).
     /// @return The total number of attestations.
    function getTotalAttestations() external view returns (uint256) {
        return _nextAttestationId - 1;
    }

    /// @notice Gets the total count of attestations for a specific type (including inactive).
    /// @param attestationTypeId The ID of the attestation type.
    /// @return The total count for the type.
    function getAttestationCountByType(uint256 attestationTypeId) external view returns (uint256) {
        // This requires iterating through all attestations, which can be gas intensive.
        // A dedicated counter per type would be more efficient if needed often.
        // For this example, we iterate the global list and check the type.
        // NOTE: This implementation might hit gas limits for very large numbers of attestations.
        uint256 count = 0;
        for(uint256 i = 1; i < _nextAttestationId; i++) {
            if (attestations[i].exists && attestations[i].attestationTypeId == attestationTypeId) {
                count++;
            }
        }
        return count;
    }


    // --- Reputation & Query ---

    /// @notice Retrieves the current reputation score for a profile.
    /// @param profileId The ID of the profile.
    /// @return The current reputation score.
    function getProfileReputation(uint256 profileId) external view returns (int256) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        // Reputation is updated incrementally on submit/revoke
        return profiles[profileId].reputationScore;
    }

    /// @notice Checks if a profile has at least one *active* attestation of a specific type.
    /// Useful for dApps querying if a profile meets a certain requirement (e.g., "has Skill: Solidity").
    /// @param profileId The ID of the profile.
    /// @param attestationTypeId The ID of the attestation type.
    /// @return True if the profile has at least one active attestation of that type, false otherwise.
    function hasAttestationTypeForProfile(uint256 profileId, uint256 attestationTypeId) external view returns (bool) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        require(attestationTypes[attestationTypeId].exists, "Attestation type does not exist");

        uint256[] storage attIds = profileAttestationIds[profileId];
        for (uint i = 0; i < attIds.length; i++) {
            if (attestations[attIds[i]].exists && attestations[attIds[i]].isActive && attestations[attIds[i]].attestationTypeId == attestationTypeId) {
                return true;
            }
        }
        return false;
    }

     /// @notice Gets the count of *active* attestations of a specific type for a profile.
    /// Useful for dApps querying strength of a profile's qualifications (e.g., "how many people attested to Skill: Solidity").
    /// @param profileId The ID of the profile.
    /// @param attestationTypeId The ID of the attestation type.
    /// @return The count of active attestations of that type for the profile.
    function getAttestationCountForTypeForProfile(uint256 profileId, uint256 attestationTypeId) external view returns (uint256) {
        require(profiles[profileId].isInitialized, "Profile does not exist");
        require(attestationTypes[attestationTypeId].exists, "Attestation type does not exist");

        uint256 count = 0;
        uint256[] storage attIds = profileAttestationIds[profileId];
        for (uint i = 0; i < attIds.length; i++) {
            if (attestations[attIds[i]].exists && attestations[attIds[i]].isActive && attestations[attIds[i]].attestationTypeId == attestationTypeId) {
                count++;
            }
        }
        return count;
    }

    /// @notice Checks if a specific attestation is currently active.
    /// @param attestationId The ID of the attestation.
    /// @return True if the attestation exists and is active, false otherwise.
    function isAttestationActive(uint256 attestationId) external view returns (bool) {
        return attestations[attestationId].exists && attestations[attestationId].isActive;
    }

    // --- Utility/View Functions ---

    /// @notice Gets the owner address of a profile.
    /// @param profileId The ID of the profile.
    /// @return The owner address.
    function getProfileOwner(uint256 profileId) external view returns (address) {
         require(profiles[profileId].isInitialized, "Profile does not exist");
         return profiles[profileId].owner;
    }

    /// @notice Checks if an address is the owner of a profile.
    /// @param profileId The ID of the profile.
    /// @param candidate The address to check.
    /// @return True if the address is the owner, false otherwise.
    function isProfileOwner(uint256 profileId, address candidate) external view returns (bool) {
         require(profiles[profileId].isInitialized, "Profile does not exist");
         return profiles[profileId].owner == candidate;
    }
}
```