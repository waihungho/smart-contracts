Okay, here is a Solidity smart contract implementing a "Decentralized Skill & Attestation Protocol". This concept involves users registering, declaring skills, receiving attestations for those skills from other users, potentially proving skills via challenges, and building up a score/reputation based on these interactions.

It's designed to be more complex than a basic token or simple registry, incorporating multiple user roles, dynamic scoring, and a verification process for skills.

**Concept:** Decentralized Skill & Attestation Protocol

**Purpose:** To create an on-chain system where users can register, declare specific skills, receive verifiable attestations from other registered users regarding those skills, and potentially undergo a verification process (a "challenge") to prove a skill, building a dynamic reputation based on these factors.

**Key Features:**

1.  **User Registration:** Users join the protocol.
2.  **Skill Catalog:** Admin/Manager defines a set of available skills.
3.  **Skill Declaration:** Registered users declare which skills they possess or are pursuing.
4.  **Attestation System:** Registered users can attest to the skills of other *registered* users, assigning a weighted endorsement.
5.  **Dynamic Skill Scores:** User skill scores are calculated based on aggregated attestation weights.
6.  **Skill Proof Challenges:** Skills can optionally have an associated on-chain challenge data set by a manager. Users can submit proof data.
7.  **Verification Role:** Designated verifiers can validate submitted skill proofs.
8.  **Verification Status:** Skills can be marked as officially "verified" for a user after proof validation.
9.  **Reputation:** A total user reputation can be calculated based on their verified skills and attestation scores.
10. **Role-Based Access Control:** Owner, Skill Manager, and Verifier roles manage different parts of the protocol.

---

**Outline:**

1.  **License and Pragma**
2.  **Error Handling:** Custom errors for clarity and gas efficiency.
3.  **State Variables:**
    *   Owner address
    *   Skill Manager address
    *   Verifier addresses map
    *   User data (address to ID, ID to address)
    *   Skill data (ID to Skill struct, list of IDs)
    *   User Skill data (user ID -> skill ID -> UserSkill struct)
    *   Attestation data (attested user ID -> skill ID -> attester user ID -> Attestation struct)
    *   Skill Proof Challenge data (skill ID -> challenge data)
    *   Counters for user IDs.
4.  **Struct Definitions:** `Skill`, `UserSkill`, `Attestation`.
5.  **Events:** For key state changes (registration, skill creation, attestation, verification, role changes).
6.  **Modifiers:** `onlyOwner`, `onlySkillManager`, `onlyVerifier`, `onlyRegisteredUser`, `skillExists`.
7.  **Core Logic Functions (Grouped):**
    *   Role Management
    *   User Registration & Lookup
    *   Skill Catalog Management
    *   User Skill Declaration & Lookup
    *   Attestation Management
    *   Skill Proof Challenge & Verification
    *   Score & Reputation Calculation (View functions)
8.  **Internal Helper Functions**

---

**Function Summary:**

*   **Role Management:**
    *   `constructor()`: Sets contract owner.
    *   `setSkillManager(address _skillManager)`: Sets the address for the Skill Manager role. (Owner only)
    *   `getSkillManager() view`: Gets the Skill Manager address.
    *   `addVerifier(address _verifier)`: Adds an address to the Verifier role. (Owner/Manager only)
    *   `removeVerifier(address _verifier)`: Removes an address from the Verifier role. (Owner/Manager only)
    *   `isVerifier(address _account) view`: Checks if an address is a Verifier.

*   **User Registration & Lookup:**
    *   `registerUser()`: Registers the calling address as a user. Assigns a unique ID.
    *   `getUserById(uint256 _userId) view`: Gets the address for a given user ID.
    *   `getUserIdByAddress(address _userAddress) view`: Gets the user ID for a given address.
    *   `isUserRegistered(address _userAddress) view`: Checks if an address is registered.

*   **Skill Catalog Management:**
    *   `createSkill(bytes32 _skillId, string calldata _name, string calldata _description)`: Creates a new skill type in the catalog. (Skill Manager only)
    *   `updateSkill(bytes32 _skillId, string calldata _newName, string calldata _newDescription)`: Updates an existing skill's details. (Skill Manager only)
    *   `getSkill(bytes32 _skillId) view`: Retrieves details for a specific skill ID.
    *   `getAllSkillIds() view`: Gets a list of all defined skill IDs.

*   **User Skill Declaration & Lookup:**
    *   `declareSkill(bytes32 _skillId)`: User declares they possess or are interested in a skill. Creates their personal entry for this skill. (Registered user only)
    *   `getUserSkill(uint256 _userId, bytes32 _skillId) view`: Gets the `UserSkill` data for a specific user and skill.
    *   `getUserDeclaredSkills(uint256 _userId) view`: Gets a list of skill IDs that a user has declared.

*   **Attestation Management:**
    *   `attestSkill(uint256 _attestedUserId, bytes32 _skillId, uint256 _weight)`: A registered user attests to another user's skill, adding weight to their score. (Registered user only, cannot attest self)
    *   `revokeAttestation(uint256 _attestedUserId, bytes32 _skillId)`: An attester revokes their previous attestation, removing its weight from the score. (Original attester only)
    *   `getAttestationDetails(uint256 _attestedUserId, bytes32 _skillId, uint256 _attesterUserId) view`: Retrieves details of a specific attestation.

*   **Skill Proof Challenge & Verification:**
    *   `setSkillProofChallenge(bytes32 _skillId, bytes calldata _challengeData)`: Sets the expected proof data for a skill challenge. (Skill Manager only)
    *   `getSkillProofChallenge(bytes32 _skillId) view`: Gets the challenge data for a skill.
    *   `submitSkillProof(bytes32 _skillId, bytes calldata _proofData)`: User submits data as proof for a skill. (Registered user, skill declared)
    *   `verifySkillProof(uint256 _userId, bytes32 _skillId)`: Verifier validates a user's submitted proof against the stored challenge data. Marks the skill as verified for the user if correct. (Verifier only)
    *   `isSkillProofVerified(uint256 _userId, bytes32 _skillId) view`: Checks if a user's proof for a skill has been verified.

*   **Score & Reputation Calculation (View functions):**
    *   `getUserSkillScore(uint256 _userId, bytes32 _skillId) view`: Gets the current aggregated attestation score for a user's skill.
    *   `calculateUserTotalReputation(uint256 _userId) view`: Calculates the user's total reputation (e.g., sum of verified skill scores + weighted sum of unverified skill scores). *Note: This is a placeholder calculation.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized Skill & Attestation Protocol
 * @author Your Name/Alias (Inspired by advanced concepts)
 * @notice A smart contract for users to register, declare skills, receive attestations,
 *         submit proofs for verification, and build dynamic reputation on-chain.
 *
 * @dev This contract is a demonstration of combining multiple concepts like identity/registry,
 *      attestation, dynamic scoring, and role-based verification in a non-standard way.
 *      It's designed for educational purposes and might require further optimization
 *      and security audits for production use, especially regarding gas costs for iteration
 *      in view functions and potential complexity in challenge proofs.
 */

// --- Outline ---
// 1. License and Pragma
// 2. Error Handling
// 3. State Variables
// 4. Struct Definitions
// 5. Events
// 6. Modifiers
// 7. Core Logic Functions (Grouped: Roles, Users, Skills, Attestation, Proofs, Scoring)

// --- Function Summary ---
// Role Management:
// - constructor()
// - setSkillManager(address _skillManager)
// - getSkillManager()
// - addVerifier(address _verifier)
// - removeVerifier(address _verifier)
// - isVerifier(address _account)
// User Registration & Lookup:
// - registerUser()
// - getUserById(uint256 _userId)
// - getUserIdByAddress(address _userAddress)
// - isUserRegistered(address _userAddress)
// Skill Catalog Management:
// - createSkill(bytes32 _skillId, string calldata _name, string calldata _description)
// - updateSkill(bytes32 _skillId, string calldata _newName, string calldata _newDescription)
// - getSkill(bytes32 _skillId)
// - getAllSkillIds()
// User Skill Declaration & Lookup:
// - declareSkill(bytes32 _skillId)
// - getUserSkill(uint256 _userId, bytes32 _skillId)
// - getUserDeclaredSkills(uint256 _userId)
// Attestation Management:
// - attestSkill(uint256 _attestedUserId, bytes32 _skillId, uint256 _weight)
// - revokeAttestation(uint256 _attestedUserId, bytes32 _skillId)
// - getAttestationDetails(uint256 _attestedUserId, bytes32 _skillId, uint256 _attesterUserId)
// Skill Proof Challenge & Verification:
// - setSkillProofChallenge(bytes32 _skillId, bytes calldata _challengeData)
// - getSkillProofChallenge(bytes32 _skillId)
// - submitSkillProof(bytes32 _skillId, bytes calldata _proofData)
// - verifySkillProof(uint256 _userId, bytes32 _skillId)
// - isSkillProofVerified(uint256 _userId, bytes32 _skillId)
// Score & Reputation Calculation (View functions):
// - getUserSkillScore(uint256 _userId, bytes32 _skillId)
// - calculateUserTotalReputation(uint256 _userId)

// --- End Summary ---

contract SkillAttestationProtocol {

    // --- Error Handling ---
    error NotOwner();
    error NotSkillManager();
    error NotVerifier();
    error NotRegisteredUser();
    error UserAlreadyRegistered();
    error UserNotFound(uint256 userId);
    error UserAddressNotFound(address userAddress);
    error SkillAlreadyExists(bytes32 skillId);
    error SkillNotFound(bytes32 skillId);
    error UserSkillNotDeclared(uint256 userId, bytes32 skillId);
    error CannotAttestSelf();
    error AttestationAlreadyExists(uint256 attesterId, uint256 attestedUserId, bytes32 skillId);
    error AttestationNotFound(uint256 attesterId, uint256 attestedUserId, bytes32 skillId);
    error ProofChallengeNotSet(bytes32 skillId);
    error ProofDataMismatch();
    error AlreadyVerified(uint256 userId, bytes32 skillId);
    error SkillProofNotSubmitted(uint256 userId, bytes32 skillId);
    error VerifierAlreadyExists(address verifier);
    error VerifierNotFound(address verifier);

    // --- State Variables ---
    address private _owner;
    address private _skillManager;
    mapping(address => bool) private _verifiers;

    // User Registry
    mapping(address => uint256) private _userAddressToId;
    mapping(uint256 => address) private _userIdToAddress;
    uint256 private _nextUserId = 1; // Start user IDs from 1

    // Skill Catalog
    struct Skill {
        string name;
        string description;
        bool exists; // To check if a skillId is valid without iterating allSkillIds
    }
    mapping(bytes32 => Skill) private _skills;
    bytes32[] private _allSkillIds; // For getAllSkillIds view function (gas warning for large lists)

    // User Skill Data
    struct UserSkill {
        uint256 score; // Aggregated attestation weight
        bytes proofData; // Submitted proof data by user
        bool isProofVerified; // Has the proof been verified by a verifier?
        bool declared; // Has the user declared this skill?
    }
    mapping(uint256 => mapping(bytes32 => UserSkill)) private _userSkills; // userId -> skillId -> UserSkillData
    mapping(uint256 => bytes32[]) private _userDeclaredSkillIds; // userId -> list of declared skillIds (gas warning)

    // Attestation Data
    struct Attestation {
        uint256 attesterId;
        uint256 weight;
        uint256 timestamp;
    }
    mapping(uint256 => mapping(bytes32 => mapping(uint256 => Attestation))) private _userSkillAttestations; // attestedUserId -> skillId -> attesterId -> AttestationData

    // Skill Proof Challenges
    mapping(bytes32 => bytes) private _skillProofChallenges; // skillId -> expected proof data

    // --- Events ---
    event UserRegistered(uint256 indexed userId, address indexed userAddress);
    event SkillCreated(bytes32 indexed skillId, string name);
    event SkillUpdated(bytes32 indexed skillId, string newName);
    event SkillDeclared(uint256 indexed userId, bytes32 indexed skillId);
    event SkillAttested(uint256 indexed attestedUserId, bytes32 indexed skillId, uint256 indexed attesterId, uint256 weight, uint256 newScore);
    event AttestationRevoked(uint256 indexed attestedUserId, bytes32 indexed skillId, uint256 indexed attesterId, uint256 oldScore, uint256 newScore);
    event SkillProofChallengeSet(bytes32 indexed skillId);
    event SkillProofSubmitted(uint256 indexed userId, bytes32 indexed skillId, bytes proofDataHash); // Log hash instead of raw data
    event SkillProofVerified(uint256 indexed userId, bytes32 indexed skillId, address indexed verifier);
    event SkillManagerSet(address indexed manager);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlySkillManager() {
        if (msg.sender != _skillManager) revert NotSkillManager();
        _;
    }

    modifier onlyVerifier() {
        if (!_verifiers[msg.sender]) revert NotVerifier();
        _;
    }

    modifier onlyRegisteredUser() {
        if (_userAddressToId[msg.sender] == 0) revert NotRegisteredUser();
        _;
    }

    modifier onlyRegisteredUser(uint256 _userId) {
         if (_userIdToAddress[_userId] == address(0)) revert UserNotFound(_userId);
         _;
    }

    modifier skillExists(bytes32 _skillId) {
        if (!_skills[_skillId].exists) revert SkillNotFound(_skillId);
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
    }

    // --- Role Management ---

    /**
     * @notice Sets the address for the Skill Manager role.
     * @dev Only the owner can set the Skill Manager.
     * @param _skillManager The address to assign the role to.
     */
    function setSkillManager(address _skillManager) external onlyOwner {
        _skillManager = _skillManager;
        emit SkillManagerSet(_skillManager);
    }

    /**
     * @notice Gets the current Skill Manager address.
     * @return The address of the Skill Manager.
     */
    function getSkillManager() external view returns (address) {
        return _skillManager;
    }

    /**
     * @notice Adds an address to the Verifier role.
     * @dev Only the owner or skill manager can add verifiers.
     * @param _verifier The address to add as a verifier.
     */
    function addVerifier(address _verifier) external onlyOwnerOrManager {
        if (_verifiers[_verifier]) revert VerifierAlreadyExists(_verifier);
        _verifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @notice Removes an address from the Verifier role.
     * @dev Only the owner or skill manager can remove verifiers.
     * @param _verifier The address to remove from the verifier role.
     */
    function removeVerifier(address _verifier) external onlyOwnerOrManager {
        if (!_verifiers[_verifier]) revert VerifierNotFound(_verifier);
        _verifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }

    /**
     * @notice Checks if an address has the Verifier role.
     * @param _account The address to check.
     * @return True if the address is a verifier, false otherwise.
     */
    function isVerifier(address _account) external view returns (bool) {
        return _verifiers[_account];
    }

    // Internal helper for owner or skill manager
    modifier onlyOwnerOrManager() {
        if (msg.sender != _owner && msg.sender != _skillManager) revert NotOwner(); // Reusing NotOwner for simplicity, could add NotAuthorized
        _;
    }

    // --- User Registration & Lookup ---

    /**
     * @notice Registers the calling address as a user in the protocol.
     * @dev Assigns a unique user ID.
     */
    function registerUser() external {
        if (_userAddressToId[msg.sender] != 0) revert UserAlreadyRegistered();

        uint256 userId = _nextUserId++;
        _userAddressToId[msg.sender] = userId;
        _userIdToAddress[userId] = msg.sender;

        emit UserRegistered(userId, msg.sender);
    }

    /**
     * @notice Gets the address associated with a user ID.
     * @param _userId The ID of the user.
     * @return The address of the user.
     */
    function getUserById(uint256 _userId) external view onlyRegisteredUser(_userId) returns (address) {
        return _userIdToAddress[_userId];
    }

    /**
     * @notice Gets the user ID associated with an address.
     * @param _userAddress The address of the user.
     * @return The ID of the user.
     */
    function getUserIdByAddress(address _userAddress) external view returns (uint256) {
        uint256 userId = _userAddressToId[_userAddress];
        if (userId == 0) revert UserAddressNotFound(_userAddress); // Specific error for address lookup
        return userId;
    }

    /**
     * @notice Checks if an address is registered as a user.
     * @param _userAddress The address to check.
     * @return True if the address is registered, false otherwise.
     */
    function isUserRegistered(address _userAddress) external view returns (bool) {
        return _userAddressToId[_userAddress] != 0;
    }

    // Internal helper to get calling user's ID
    function _getCurrentUserId() internal view returns (uint256) {
        uint256 userId = _userAddressToId[msg.sender];
        if (userId == 0) revert NotRegisteredUser();
        return userId;
    }

    // --- Skill Catalog Management ---

    /**
     * @notice Creates a new skill type in the protocol catalog.
     * @dev Requires the Skill Manager role. Skill ID must be unique.
     * @param _skillId A unique identifier for the skill (e.g., keccak256("Solidity Programming")).
     * @param _name The human-readable name of the skill.
     * @param _description A brief description of the skill.
     */
    function createSkill(bytes32 _skillId, string calldata _name, string calldata _description) external onlySkillManager {
        if (_skills[_skillId].exists) revert SkillAlreadyExists(_skillId);

        _skills[_skillId] = Skill({
            name: _name,
            description: _description,
            exists: true
        });
        _allSkillIds.push(_skillId);

        emit SkillCreated(_skillId, _name);
    }

    /**
     * @notice Updates the name and description of an existing skill.
     * @dev Requires the Skill Manager role.
     * @param _skillId The ID of the skill to update.
     * @param _newName The new human-readable name for the skill.
     * @param _newDescription The new description for the skill.
     */
    function updateSkill(bytes32 _skillId, string calldata _newName, string calldata _newDescription) external onlySkillManager skillExists(_skillId) {
        _skills[_skillId].name = _newName;
        _skills[_skillId].description = _newDescription;

        emit SkillUpdated(_skillId, _newName);
    }

    /**
     * @notice Retrieves details for a specific skill.
     * @param _skillId The ID of the skill.
     * @return name The human-readable name.
     * @return description The description.
     * @return exists True if the skill exists.
     */
    function getSkill(bytes32 _skillId) external view skillExists(_skillId) returns (string memory name, string memory description, bool exists) {
        Skill storage s = _skills[_skillId];
        return (s.name, s.description, s.exists);
    }

     /**
     * @notice Gets a list of all skill IDs in the catalog.
     * @dev This function iterates over an array and can be gas-expensive for a large number of skills.
     * @return An array of all skill IDs.
     */
    function getAllSkillIds() external view returns (bytes32[] memory) {
        return _allSkillIds;
    }

    // --- User Skill Declaration & Lookup ---

    /**
     * @notice A registered user declares they possess or are interested in a specific skill.
     * @dev Creates the user's personal entry for this skill if it doesn't exist.
     * @param _skillId The ID of the skill being declared.
     */
    function declareSkill(bytes32 _skillId) external onlyRegisteredUser skillExists(_skillId) {
        uint256 userId = _getCurrentUserId();
        UserSkill storage userSkill = _userSkills[userId][_skillId];

        if (!userSkill.declared) {
            userSkill.declared = true;
            // Add skillId to user's list if not already present
            bool alreadyAdded = false;
            for (uint i = 0; i < _userDeclaredSkillIds[userId].length; i++) {
                if (_userDeclaredSkillIds[userId][i] == _skillId) {
                    alreadyAdded = true;
                    break;
                }
            }
            if (!alreadyAdded) {
                _userDeclaredSkillIds[userId].push(_skillId);
            }
            emit SkillDeclared(userId, _skillId);
        }
        // No error if already declared, just no state change/event
    }

    /**
     * @notice Gets the `UserSkill` data for a specific user and skill.
     * @param _userId The ID of the user.
     * @param _skillId The ID of the skill.
     * @return score The aggregated attestation score.
     * @return isProofVerified Whether the skill proof is verified.
     * @return declared Whether the user has declared this skill.
     */
    function getUserSkill(uint256 _userId, bytes32 _skillId) external view onlyRegisteredUser(_userId) skillExists(_skillId) returns (uint256 score, bool isProofVerified, bool declared) {
         UserSkill storage userSkill = _userSkills[_userId][_skillId];
         // Note: proofData is not returned publicly here for potential privacy/gas reasons
         return (userSkill.score, userSkill.isProofVerified, userSkill.declared);
    }

    /**
     * @notice Gets a list of all skill IDs that a user has declared.
     * @dev This function iterates over an array and can be gas-expensive for users with many declared skills.
     * @param _userId The ID of the user.
     * @return An array of skill IDs.
     */
    function getUserDeclaredSkills(uint256 _userId) external view onlyRegisteredUser(_userId) returns (bytes32[] memory) {
        return _userDeclaredSkillIds[_userId];
    }


    // --- Attestation Management ---

    /**
     * @notice A registered user attests to another registered user's skill.
     * @dev Adds weight to the attested user's skill score.
     * Requires the attested user to be registered and the skill to exist. Cannot attest yourself.
     * Only one attestation per attester per user/skill combination is counted. Subsequent attestations from the same attester overwrite the previous one.
     * @param _attestedUserId The ID of the user whose skill is being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _weight The weight of the attestation (e.g., 1 to 100). A weight of 0 can be used to effectively remove an attestation.
     */
    function attestSkill(uint256 _attestedUserId, bytes32 _skillId, uint256 _weight) external onlyRegisteredUser skillExists(_skillId) {
        uint256 attesterUserId = _getCurrentUserId();
        if (attesterUserId == _attestedUserId) revert CannotAttestSelf();
        if (_userIdToAddress[_attestedUserId] == address(0)) revert UserNotFound(_attestedUserId);

        // Ensure the attested user has at least declared the skill
        UserSkill storage attestedUserSkill = _userSkills[_attestedUserId][_skillId];
        if (!attestedUserSkill.declared) {
             // Automatically declare the skill for the user if it's attested?
             // Or require declaration first? Let's require declaration first.
             revert UserSkillNotDeclared(_attestedUserId, _skillId);
        }

        Attestation storage existingAttestation = _userSkillAttestations[_attestedUserId][_skillId][attesterUserId];

        uint256 oldScore = attestedUserSkill.score;
        uint256 newScore = oldScore;

        if (existingAttestation.timestamp == 0) {
            // First attestation from this attester
            newScore = oldScore + _weight;
        } else {
            // Update existing attestation
            newScore = (oldScore - existingAttestation.weight) + _weight;
        }

        existingAttestation.attesterId = attesterUserId; // Should already be this, but for completeness
        existingAttestation.weight = _weight;
        existingAttestation.timestamp = block.timestamp;

        attestedUserSkill.score = newScore;

        emit SkillAttested(_attestedUserId, _skillId, attesterUserId, _weight, newScore);
    }

    /**
     * @notice An attester revokes their previous attestation for a user's skill.
     * @dev Requires the calling user to be the original attester.
     * Removes the attestation weight from the attested user's skill score.
     * @param _attestedUserId The ID of the user whose skill was attested.
     * @param _skillId The ID of the skill that was attested.
     */
    function revokeAttestation(uint256 _attestedUserId, bytes32 _skillId) external onlyRegisteredUser skillExists(_skillId) {
        uint256 attesterUserId = _getCurrentUserId();
        if (_attestedUserId == attesterUserId) revert CannotAttestSelf(); // Should not happen via AttestSkill path, but good check.
        if (_userIdToAddress[_attestedUserId] == address(0)) revert UserNotFound(_attestedUserId);

        Attestation storage existingAttestation = _userSkillAttestations[_attestedUserId][_skillId][attesterUserId];
        if (existingAttestation.timestamp == 0) revert AttestationNotFound(attesterUserId, _attestedUserId, _skillId);

        UserSkill storage attestedUserSkill = _userSkills[_attestedUserId][_skillId];
        uint256 oldScore = attestedUserSkill.score;
        uint256 weightToRemove = existingAttestation.weight;

        // Remove the attestation entry
        delete _userSkillAttestations[_attestedUserId][_skillId][attesterUserId];

        // Update score
        uint256 newScore = oldScore - weightToRemove;
        attestedUserSkill.score = newScore;

        emit AttestationRevoked(_attestedUserId, _skillId, attesterUserId, oldScore, newScore);
    }

    /**
     * @notice Retrieves the details of a specific attestation.
     * @dev Allows anyone to view attestation details given the parties and skill.
     * @param _attestedUserId The ID of the user whose skill was attested.
     * @param _skillId The ID of the skill that was attested.
     * @param _attesterUserId The ID of the user who made the attestation.
     * @return attesterId The ID of the attester.
     * @return weight The weight of the attestation.
     * @return timestamp The timestamp of the attestation.
     */
    function getAttestationDetails(uint256 _attestedUserId, bytes32 _skillId, uint256 _attesterUserId) external view returns (uint256 attesterId, uint256 weight, uint256 timestamp) {
        // No registration check here, allow anyone to lookup public attestations by ID
        if (_userIdToAddress[_attestedUserId] == address(0)) revert UserNotFound(_attestedUserId);
        if (_userIdToAddress[_attesterUserId] == address(0)) revert UserNotFound(_attesterUserId); // Ensure attester ID is valid
        if (!_skills[_skillId].exists) revert SkillNotFound(_skillId);

        Attestation storage att = _userSkillAttestations[_attestedUserId][_skillId][_attesterUserId];
        if (att.timestamp == 0) revert AttestationNotFound(_attesterUserId, _attestedUserId, _skillId);

        return (att.attesterId, att.weight, att.timestamp);
    }


    // --- Skill Proof Challenge & Verification ---

    /**
     * @notice Sets the expected proof data for a skill challenge.
     * @dev Requires the Skill Manager role.
     * This data is used by verifiers to check user-submitted proofs.
     * @param _skillId The ID of the skill.
     * @param _challengeData The bytes data that represents the correct proof for the skill.
     */
    function setSkillProofChallenge(bytes32 _skillId, bytes calldata _challengeData) external onlySkillManager skillExists(_skillId) {
        _skillProofChallenges[_skillId] = _challengeData;
        emit SkillProofChallengeSet(_skillId);
    }

    /**
     * @notice Gets the challenge data for a skill proof.
     * @dev Allows anyone to view the challenge data.
     * @param _skillId The ID of the skill.
     * @return The challenge data bytes.
     */
    function getSkillProofChallenge(bytes32 _skillId) external view skillExists(_skillId) returns (bytes memory) {
        bytes storage challenge = _skillProofChallenges[_skillId];
        if (challenge.length == 0) revert ProofChallengeNotSet(_skillId);
        return challenge;
    }

    /**
     * @notice User submits data as proof for a skill.
     * @dev Requires the user to be registered and to have declared the skill.
     * Stores the submitted proof data. Verification is a separate step by a verifier.
     * @param _skillId The ID of the skill the proof is for.
     * @param _proofData The data submitted as proof.
     */
    function submitSkillProof(bytes32 _skillId, bytes calldata _proofData) external onlyRegisteredUser skillExists(_skillId) {
        uint256 userId = _getCurrentUserId();
        UserSkill storage userSkill = _userSkills[userId][_skillId];

        if (!userSkill.declared) revert UserSkillNotDeclared(userId, _skillId);
        if (userSkill.isProofVerified) revert AlreadyVerified(userId, _skillId);

        userSkill.proofData = _proofData;
        // Mark verification status as false, requires verifier to set to true
        userSkill.isProofVerified = false;

        emit SkillProofSubmitted(userId, _skillId, keccak256(_proofData)); // Log hash instead of full data
    }

    /**
     * @notice A Verifier validates a user's submitted proof against the stored challenge data.
     * @dev Requires the Verifier role. If the submitted proof matches the challenge data, the user's skill is marked as verified.
     * @param _userId The ID of the user who submitted the proof.
     * @param _skillId The ID of the skill the proof is for.
     */
    function verifySkillProof(uint256 _userId, bytes32 _skillId) external onlyVerifier skillExists(_skillId) onlyRegisteredUser(_userId) {
        UserSkill storage userSkill = _userSkills[_userId][_skillId];

        if (!userSkill.declared) revert UserSkillNotDeclared(_userId, _skillId);
        if (userSkill.isProofVerified) revert AlreadyVerified(_userId, _skillId);
        if (userSkill.proofData.length == 0) revert SkillProofNotSubmitted(_userId, _skillId);

        bytes storage challengeData = _skillProofChallenges[_skillId];
        if (challengeData.length == 0) revert ProofChallengeNotSet(_skillId);

        // Compare submitted proof data with challenge data
        if (keccak256(userSkill.proofData) != keccak256(challengeData)) {
            // Optionally delete submitted proof or keep it for review
            // delete userSkill.proofData; // Could clear incorrect proof
            revert ProofDataMismatch();
        }

        // Proof is correct, mark as verified
        userSkill.isProofVerified = true;
        // Optionally clear submitted proof data after successful verification
        delete userSkill.proofData;

        emit SkillProofVerified(_userId, _skillId, msg.sender);
    }

    /**
     * @notice Checks if a user's proof for a specific skill has been verified.
     * @dev Allows anyone to check verification status.
     * @param _userId The ID of the user.
     * @param _skillId The ID of the skill.
     * @return True if the skill proof is verified for the user, false otherwise.
     */
    function isSkillProofVerified(uint256 _userId, bytes32 _skillId) external view returns (bool) {
         // No registration check needed for public view of status
         if (_userIdToAddress[_userId] == address(0)) return false; // User not found
         if (!_skills[_skillId].exists) return false; // Skill not found
         return _userSkills[_userId][_skillId].isProofVerified;
    }


    // --- Score & Reputation Calculation ---

    /**
     * @notice Gets the current aggregated attestation score for a user's specific skill.
     * @dev Sum of weights from all attestations for this user/skill.
     * @param _userId The ID of the user.
     * @param _skillId The ID of the skill.
     * @return The aggregated attestation score. Returns 0 if the user hasn't declared the skill.
     */
    function getUserSkillScore(uint256 _userId, bytes32 _skillId) external view returns (uint256) {
        // No registration/skillExists checks needed, returns 0 if not found
        return _userSkills[_userId][_skillId].score;
    }

    /**
     * @notice Calculates a user's total reputation score based on their skills.
     * @dev This is an example calculation. It sums scores for verified skills, and optionally includes
     *      a weighted sum of scores for unverified skills.
     *      Note: Iterating over `_userDeclaredSkillIds` can be gas-expensive for users with many skills.
     * @param _userId The ID of the user.
     * @return The calculated total reputation score.
     */
    function calculateUserTotalReputation(uint256 _userId) external view onlyRegisteredUser(_userId) returns (uint256) {
        uint256 totalReputation = 0;
        bytes32[] storage declaredSkills = _userDeclaredSkillIds[_userId];

        // Example calculation: Sum verified skill scores directly,
        // and add a fraction of unverified skill scores.
        uint256 VERIFIED_WEIGHT = 1; // Verified score contributes fully
        uint256 UNVERIFIED_WEIGHT_DIVISOR = 2; // Unverified score contributes half

        for (uint i = 0; i < declaredSkills.length; i++) {
            bytes32 skillId = declaredSkills[i];
            UserSkill storage userSkill = _userSkills[_userId][skillId];

            if (userSkill.declared) { // Should always be true if in declaredSkills list
                 if (userSkill.isProofVerified) {
                     totalReputation += userSkill.score * VERIFIED_WEIGHT;
                 } else {
                     totalReputation += userSkill.score / UNVERIFIED_WEIGHT_DIVISOR;
                 }
            }
        }

        return totalReputation;
    }

    // --- Internal Helper Functions ---
    // (None critical enough yet that aren't inline, but add them here if needed)
}
```