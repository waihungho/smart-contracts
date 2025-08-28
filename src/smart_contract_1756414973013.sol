Here's a smart contract written in Solidity that embodies several advanced, creative, and trendy concepts without directly duplicating existing open-source projects. It focuses on a "Synthetic Digital Identity & Reputation (SDIR)" system, integrating dynamic NFTs, AI/ML oracle attestations (simulated), multi-dimensional reputation, and a basic dispute mechanism.

**Core Idea: AuraGenesis - Dynamic Soulbound Identity & Reputation**

AuraGenesis allows users to mint a non-transferable (Soulbound) NFT that represents their digital identity. This SBNFT dynamically evolves its traits and "archetype" based on on-chain activities and privacy-preserving attestations submitted by whitelisted AI/ML oracles. This system aims to provide a robust, Sybil-resistant, and dynamic digital identity for Web3 ecosystems, facilitating personalized experiences, advanced access control, and reputation-driven governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// --- Custom Errors for better gas efficiency ---
error NotOwner(); // Generic access error for non-identity owner
error NotOracle(); // Caller is not a whitelisted oracle
error IdentityAlreadyExists(); // User already has an active SBNFT
error IdentityDoesNotExist(); // User does not have an active SBNFT, or token ID is invalid
error NotAuthorized(); // Caller lacks general permissions or is not a delegate
error AttestationNotFound(); // Specific attestation hash not found
error TraitAlreadyClaimed(); // User already possesses the requested trait
error TraitNotEligible(); // User does not meet the requirements to unlock a trait
error InvalidReputationRatios(); // Malformed reputation ratio input for archetype
error ChallengeInProgress(); // An attestation is already under dispute
error NoActiveChallenge(); // No dispute found for the given attestation hash
error AlreadyVoted(); // Oracle already voted on a specific challenge
error ChallengeNotResolved(); // Dispute state is not yet final
error InvalidTraitId(); // Trait ID is not recognized or configured
error InvalidArchetypeId(); // Archetype ID is not recognized or configured
error NoAttestationFound(); // No attestation exists for the provided hash

/*
    Contract Name: AuraGenesis
    Description: AuraGenesis is an advanced, Soulbound Identity & Reputation (SDIR) system.
                 It enables users to mint a non-transferable NFT (Soulbound Identity NFT - SBNFT)
                 that dynamically evolves its traits and "archetype" based on on-chain activities
                 and privacy-preserving attestations submitted by whitelisted AI/ML oracles.
                 This system aims to provide a robust, Sybil-resistant, and dynamic digital identity
                 for Web3 ecosystems, facilitating personalized experiences, advanced access control,
                 and reputation-driven governance.

    Key Concepts:
    - Soulbound Identity NFTs (SBNFTs): Non-transferable tokens representing a user's digital identity,
      with dynamic metadata and traits that cannot be transferred.
    - Multi-dimensional Reputation System: Tracks various reputation scores (e.g., Engagement, Reliability, Creativity)
      that influence SBNFT evolution and archetype assignment.
    - AI/ML Oracle Attestation (Simulated): A whitelisted network of oracles (simulated as addresses) submits
      aggregated, privacy-preserving data attestations to update user reputation scores and trigger trait upgrades.
    - Dynamic Trait & Archetype Progression: SBNFTs visually and functionally evolve. Users unlock new 'traits'
      and are assigned "archetypes" (e.g., 'Builder', 'Community Leader') based on their reputation scores.
      The NFT's metadata (tokenURI) dynamically reflects these changes.
    - Delegation: SBNFT owners can delegate specific permissions (e.g., challenging attestations, claiming traits)
      to other addresses, enhancing flexible identity management.
    - Dispute Mechanism: A simplified on-chain system allows users to challenge oracle attestations. Oracles
      can then vote on these challenges, with the contract owner ultimately resolving them and potentially
      reverting reputation changes.

    Outline:
    I.  State Variables & Data Structures: Definitions of structs, mappings, and constants.
    II. Events: Log significant actions and state changes within the contract.
    III.Modifiers: Reusable access control and state validation checks.
    IV. Constructor & Initialization: Sets up the contract and initial oracle.
    V.  Core Identity & SBNFT Management: Functions for minting, querying, and managing the lifecycle of SBNFTs.
    VI. Reputation & Trait Progression: Functions related to earning reputation, unlocking traits, and determining archetypes.
    VII.Oracle & Admin Management: Functions for configuring oracles, attestation types, traits, and archetypes.
    VIII.Delegation & Privacy: Functions for delegating identity permissions and linking privacy-preserving data.
    IX. Dispute System: Functions for challenging attestations, voting on challenges, and resolving disputes.
    X.  Internal Helper Functions: Private functions used by the contract's core logic.
*/

/*
    Function Summary (25 External/Public functions + 7 Internal functions = 32 Total):

    I. Core Identity & SBNFT Management (7 external/public, 3 internal):
    1.  initializeIdentity(): Mints a new Soulbound Identity NFT (SBNFT) for the caller.
    2.  getIdentityNFTId(address user): Returns the SBNFT ID associated with a user's address.
    3.  getCurrentTraits(uint256 tokenId): Retrieves a list of the active trait names for an SBNFT.
    4.  isIdentityActive(address user): Checks if a user currently holds an active SBNFT.
    5.  ownerOf(uint256 tokenId): Returns the owner of the SBNFT (standard ERC721 interface, non-transferable).
    6.  adminRevokeIdentity(uint256 tokenId): Callable by owner to revoke (burn) an SBNFT, e.g., for policy violations.
    7.  adminRecoverIdentity(uint256 tokenId, address newOwner): Callable by owner to recover a revoked SBNFT, reassigning it.
    8.  _exists(uint256 tokenId): INTERNAL - Checks if an SBNFT with a given ID exists and is active.
    9.  _mintSBNFT(address owner): INTERNAL - Mints a new SBNFT for the specified owner.
    10. tokenURI(uint256 tokenId): INTERNAL - Generates a dynamic JSON metadata URI for a given SBNFT, reflecting its current traits and archetype.

    II. Reputation & Trait Progression (6 external/public, 1 internal):
    11. getReputationScores(address user): Returns the current reputation scores across all categories for a user.
    12. submitAttestation(address targetUser, bytes32 attestationType, uint256 value, bytes32 attestationHash): Allows whitelisted oracles to submit attestations, updating target user's reputation.
    13. getArchetype(address user): Determines and returns the user's current 'archetype' string based on their reputation.
    14. getTraitProgression(address user, bytes32 traitId): Shows the user's progress towards unlocking a specific trait, listing current scores vs. thresholds.
    15. checkTraitEligibility(address user, bytes32 traitId): Verifies if a user meets the requirements to unlock a given trait.
    16. claimTraitUpgrade(uint256 tokenId, bytes32 traitId): Allows an eligible user (or delegate) to claim and apply a new trait to their SBNFT.
    17. _processAttestation(address user, bytes32 attestationType, uint256 value): INTERNAL - Updates reputation based on a new attestation.

    III. Oracle & Admin Management (5 external/public):
    18. addAttestationOracle(address oracleAddress): Adds a new address to the list of approved attestor oracles (Owner only).
    19. removeAttestationOracle(address oracleAddress): Removes an address from the approved attestor oracles (Owner only).
    20. setAttestationTypeWeight(bytes32 attestationType, uint256 weight): Sets the impact weight for a specific attestation type on reputation (Owner only).
    21. setTraitUnlockCondition(bytes32 traitId, string memory name, string memory description, string memory imgURI, bytes32 reputationType, uint256 threshold): Defines a new trait and its unlock condition(s) (Owner only).
    22. setArchetypeCondition(uint256 archetypeId, string memory name, bytes32[] memory reputationTypes, uint256[] memory minRatios, uint256[] memory maxRatios): Configures the reputation ratio requirements for an archetype (Owner only).

    IV. Delegation & Privacy (4 external/public):
    23. delegateIdentityFunction(address delegatee, uint256 functionMask): Allows an SBNFT owner to delegate specific control functions to another address.
    24. revokeDelegate(address delegatee): Revokes all delegated permissions for a specific address.
    25. getDelegatedFunctions(address owner, address delegatee): Returns the function mask for a delegatee.
    26. updateIdentityProfileHash(uint256 tokenId, bytes32 profileHash): Allows SBNFT owners to link a privacy-preserving hash (e.g., ZK proof commitment) to their identity.

    V. Dispute System (3 external/public):
    27. challengeAttestation(bytes32 attestationHash, string memory reason): Allows a user (or delegate) to challenge a specific attestation made against them.
    28. voteOnAttestationChallenge(bytes32 attestationHash, bool approve): Allows whitelisted oracles to vote on a challenged attestation's validity.
    29. resolveAttestationChallenge(bytes32 attestationHash): Callable by owner to finalize a challenged attestation based on oracle votes, potentially reverting reputation changes.

    VI. Internal Helper Functions (3 internal):
    30. _calculateCurrentArchetype(address user): INTERNAL - Calculates the current archetype for a user based on their reputation distribution.
    31. _checkTraitConditions(address user, bytes32 traitId): INTERNAL - Checks if all defined conditions for a trait are met by a user.
    32. _getReputationScore(address user, bytes32 repType): INTERNAL - Retrieves a specific reputation score for a user.
*/


contract AuraGenesis is Ownable {
    // I. State Variables & Data Structures
    using Counters for Counters.Counter;
    using Strings for uint256; // For toString() conversion

    // --- Data Structures ---
    // Stores a user's multi-dimensional reputation scores
    struct ReputationScores {
        mapping(bytes32 => uint256) scores; // e.g., keccak256("Engagement") => 100
        uint256 lastUpdated;
    }

    // Defines a possible trait for an SBNFT
    struct Trait {
        string name;
        string description;
        string imgURI; // Base URI for trait image
        bool active; // Is this trait currently enabled in the system?
    }

    // Defines a single condition required to unlock a trait
    struct TraitUnlockCondition {
        bytes32 reputationType; // e.g., keccak256("Engagement")
        uint256 threshold;      // Minimum score required
    }

    // Defines the criteria for an SBNFT to be assigned a specific Archetype
    struct ArchetypeCondition {
        bytes32[] reputationTypes; // e.g., [keccak256("Engagement"), keccak256("Reliability")]
        uint256[] minRatios;     // Minimum ratio (value * 10000) of `reputationType`'s score to total reputation
        uint256[] maxRatios;     // Maximum ratio (value * 10000) of `reputationType`'s score to total reputation
    }

    // Represents an attestation submitted by an oracle
    struct Attestation {
        address oracle;
        address targetUser;
        bytes32 attestationType;
        uint256 value;
        uint256 timestamp;
        bool disputed; // Is this attestation currently under dispute?
        bool resolved; // Has this attestation been involved in a resolved dispute?
        bytes32 originalHash; // The hash used to identify this attestation
    }

    // Represents an active challenge against an attestation
    struct AttestationChallenge {
        bytes32 attestationHash;
        address challenger;
        string reason;
        uint256 challengeTimestamp;
        uint256 totalVotes;
        uint256 approvedVotes; // Number of oracles who voted to approve the challenge (attestation is false)
        uint256 rejectedVotes; // Number of oracles who voted to reject the challenge (attestation is true)
        mapping(address => bool) hasVoted; // Tracks which oracles have voted
        bool resolved; // Has this challenge been formally resolved?
        bool approvedByMajority; // True if the challenge was approved by majority vote (attestation was deemed false)
    }

    // --- Delegation Permissions Bitmask Constants ---
    uint256 public constant DELEGATE_CHALLENGE_ATTESTATION = 1 << 0; // Permission to challenge attestations
    uint256 public constant DELEGATE_CLAIM_TRAIT = 1 << 1;           // Permission to claim unlocked traits
    // Future permissions can be added: 1 << 2, 1 << 3, etc.

    // --- Global Counters ---
    Counters.Counter private _tokenIdCounter; // Counter for unique SBNFT IDs

    // --- Identity & SBNFT Mappings ---
    mapping(address => uint256) private _identityNFTIds;             // Maps user address to their SBNFT ID (0 if none)
    mapping(uint256 => address) private _identityOwners;             // Maps SBNFT ID to its current owner (fixed once minted)
    mapping(uint256 => mapping(bytes32 => bool)) private _identityTraits; // Maps SBNFT ID to its active traits
    mapping(uint256 => bytes32) private _identityProfileHashes;      // Maps SBNFT ID to an off-chain privacy-preserving hash
    mapping(uint256 => bool) private _activeNFTs;                   // Maps SBNFT ID to its active status (true if not revoked)

    // --- Reputation System Mappings ---
    mapping(address => ReputationScores) private _reputationScores; // Stores multi-dimensional reputation scores for each user

    // --- Oracle & Admin Mappings ---
    mapping(address => bool) private _isAttestationOracle;          // Whitelist of addresses allowed to submit attestations
    mapping(bytes32 => uint256) private _attestationTypeWeights;    // Weight multiplier for specific attestation types (default 1 if not set)

    // --- Trait Mappings ---
    mapping(bytes32 => Trait) private _traits;                      // Stores details for each defined trait (traitId => Trait struct)
    mapping(bytes32 => TraitUnlockCondition[]) private _traitUnlockConditions; // Stores an array of conditions for each trait
    bytes32[] private _allTraitIds; // An array to hold all defined trait IDs for easy iteration

    // --- Archetype Mappings ---
    mapping(uint256 => ArchetypeCondition) private _archetypeConditions; // Stores conditions for each archetype (archetypeId => ArchetypeCondition struct)
    mapping(uint256 => string) private _archetypeNames;             // Maps archetype ID to its human-readable name
    uint256 private _nextArchetypeId = 1; // Counter for assigning new archetype IDs sequentially

    // --- Attestation & Challenge Mappings ---
    mapping(bytes32 => Attestation) private _attestations;          // Stores all submitted attestations (hash => Attestation struct)
    mapping(bytes32 => AttestationChallenge) private _attestationChallenges; // Stores active and resolved challenges (hash => AttestationChallenge struct)

    // --- Delegation Mappings ---
    mapping(address => mapping(address => uint256)) private _delegations; // owner => delegatee => functionMask (bitmask of delegated permissions)

    // --- NFT Metadata ---
    string private _baseTokenURI; // Base URI for SBNFT metadata (e.g., pointing to an API for dynamic image generation)
    string public name = "AuraGenesis Identity"; // ERC721 compatibility
    string public symbol = "AGID";               // ERC721 compatibility

    // II. Events
    event IdentityMinted(address indexed owner, uint256 indexed tokenId);
    event IdentityRevoked(uint256 indexed tokenId, address indexed originalOwner);
    event IdentityRecovered(uint256 indexed tokenId, address indexed newOwner);
    event ReputationUpdated(address indexed user, bytes32 indexed reputationType, uint256 newScore);
    event AttestationSubmitted(address indexed oracle, address indexed targetUser, bytes32 attestationType, uint256 value, bytes32 attestationHash);
    event TraitUnlocked(uint256 indexed tokenId, bytes32 indexed traitId);
    event OracleAdded(address indexed oracleAddress);
    event OracleRemoved(address indexed oracleAddress);
    event AttestationTypeWeightSet(bytes32 indexed attestationType, uint256 weight);
    event TraitUnlockConditionSet(bytes32 indexed traitId, string traitName, bytes32 reputationType, uint256 threshold);
    event ArchetypeConditionSet(uint256 indexed archetypeId, string archetypeName);
    event IdentityProfileHashUpdated(uint256 indexed tokenId, bytes32 profileHash);
    event DelegateAssigned(address indexed owner, address indexed delegatee, uint256 functionMask);
    event DelegateRevoked(address indexed owner, address indexed delegatee);
    event AttestationChallenged(bytes32 indexed attestationHash, address indexed challenger);
    event AttestationChallengeVoted(bytes32 indexed attestationHash, address indexed voter, bool approved);
    event AttestationChallengeResolved(bytes32 indexed attestationHash, bool approvedByMajority, bool reputationReverted);

    // III. Modifiers
    modifier onlyOracle() {
        if (!_isAttestationOracle[msg.sender]) revert NotOracle();
        _;
    }

    modifier onlyIdentityOwner(uint256 tokenId) {
        if (!_exists(tokenId) || _identityOwners[tokenId] != msg.sender) revert NotOwner();
        _;
    }

    modifier onlyActiveIdentity(address user) {
        if (_identityNFTIds[user] == 0 || !_activeNFTs[_identityNFTIds[user]]) revert IdentityDoesNotExist();
        _;
    }

    // Allows either the owner or a designated delegate with specific permissions to call a function.
    modifier onlySelfOrDelegated(address _owner, uint256 _functionMask) {
        bool isSelf = msg.sender == _owner;
        bool isDelegate = (_delegations[_owner][msg.sender] & _functionMask) == _functionMask;
        if (!isSelf && !isDelegate) revert NotAuthorized();
        _;
    }

    // IV. Constructor & Initialization
    constructor(address initialOracle) Ownable(msg.sender) {
        // Set the initial oracle for the system
        _isAttestationOracle[initialOracle] = true;
        emit OracleAdded(initialOracle);
        // Placeholder base URI; in production, this would point to a service for dynamic metadata/images
        _baseTokenURI = "https://aura-genesis.xyz/api/metadata/"; 
    }

    // V. Core Identity & SBNFT Management (7 external/public, 3 internal)

    /**
     * @notice Mints a new Soulbound Identity NFT (SBNFT) for the caller.
     *         A user can only mint one active SBNFT.
     */
    function initializeIdentity() external {
        if (_identityNFTIds[msg.sender] != 0 && _activeNFTs[_identityNFTIds[msg.sender]]) {
            revert IdentityAlreadyExists();
        }
        _mintSBNFT(msg.sender);
    }

    /**
     * @notice Returns the SBNFT ID associated with a user's address.
     * @param user The address of the user.
     * @return The SBNFT ID, or 0 if the user does not have an active identity.
     */
    function getIdentityNFTId(address user) external view returns (uint256) {
        return _identityNFTIds[user];
    }

    /**
     * @notice Retrieves a list of the active trait names for an SBNFT.
     * @param tokenId The ID of the SBNFT.
     * @return An array of strings, where each string is the name of an active trait.
     */
    function getCurrentTraits(uint256 tokenId) external view returns (string[] memory) {
        if (!_exists(tokenId)) revert IdentityDoesNotExist();

        bytes32[] memory activeTraitIds = new bytes32[](_allTraitIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < _allTraitIds.length; i++) {
            if (_identityTraits[tokenId][_allTraitIds[i]]) {
                activeTraitIds[count] = _allTraitIds[i];
                count++;
            }
        }

        string[] memory activeTraitNames = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            activeTraitNames[i] = _traits[activeTraitIds[i]].name;
        }
        return activeTraitNames;
    }

    /**
     * @notice Checks if a user currently holds an active SBNFT.
     * @param user The address of the user.
     * @return True if the user has an active SBNFT, false otherwise.
     */
    function isIdentityActive(address user) external view returns (bool) {
        uint256 tokenId = _identityNFTIds[user];
        return _exists(tokenId);
    }

    /**
     * @notice Returns the owner of the SBNFT. This function adheres to the ERC721
     *         interface, but transfers are explicitly disabled (Soulbound nature).
     * @param tokenId The ID of the SBNFT.
     * @return The address of the owner.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert IdentityDoesNotExist();
        return _identityOwners[tokenId];
    }

    /**
     * @notice Callable by the contract owner to revoke (burn) an SBNFT.
     *         This is typically used for policy violations or malicious behavior.
     * @param tokenId The ID of the SBNFT to revoke.
     */
    function adminRevokeIdentity(uint256 tokenId) external onlyOwner {
        _revokeIdentity(tokenId);
    }

    /**
     * @notice Callable by the contract owner to recover a previously revoked SBNFT,
     *         potentially reassigning it to a new owner if the original owner
     *         is no longer valid or after an appeal process.
     * @param tokenId The ID of the SBNFT to recover.
     * @param newOwner The address to assign ownership of the recovered SBNFT.
     */
    function adminRecoverIdentity(uint256 tokenId, address newOwner) external onlyOwner {
        _recoverIdentity(tokenId, newOwner);
    }

    /**
     * @notice INTERNAL - Checks if an SBNFT with a given ID exists and is currently active.
     * @param tokenId The ID of the SBNFT.
     * @return True if the SBNFT is active, false otherwise.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId != 0 && _identityOwners[tokenId] != address(0) && _activeNFTs[tokenId];
    }

    /**
     * @notice INTERNAL - Mints a new SBNFT for the specified owner.
     *         Handles internal logic for ID assignment and initial state.
     * @param owner The address to mint the SBNFT for.
     * @return The newly minted SBNFT ID.
     */
    function _mintSBNFT(address owner) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _identityNFTIds[owner] = newTokenId;
        _identityOwners[newTokenId] = owner;
        _activeNFTs[newTokenId] = true;

        // Reputation scores are implicitly initialized to 0 for new types when queried.
        emit IdentityMinted(owner, newTokenId);
        return newTokenId;
    }

    /**
     * @notice INTERNAL - Revokes (effectively burns/deactivates) an SBNFT.
     *         Removes its active status and disassociates it from the owner's address.
     * @param tokenId The ID of the SBNFT to revoke.
     */
    function _revokeIdentity(uint256 tokenId) internal {
        if (!_exists(tokenId)) revert IdentityDoesNotExist();
        address owner = _identityOwners[tokenId];

        _activeNFTs[tokenId] = false; // Mark as inactive
        delete _identityNFTIds[owner]; // Remove mapping from address to token, making it unassignable

        emit IdentityRevoked(tokenId, owner);
    }

    /**
     * @notice INTERNAL - Recovers a previously revoked SBNFT, reactivating it and potentially
     *         assigning it to a new owner.
     * @param tokenId The ID of the SBNFT to recover.
     * @param newOwner The address to which the SBNFT will be recovered.
     */
    function _recoverIdentity(uint256 tokenId, address newOwner) internal {
        if (_identityOwners[tokenId] == address(0)) revert IdentityDoesNotExist(); // Token ID must have existed historically
        if (_activeNFTs[tokenId]) revert IdentityAlreadyExists(); // Cannot recover an already active identity
        if (_identityNFTIds[newOwner] != 0 && _activeNFTs[_identityNFTIds[newOwner]]) revert IdentityAlreadyExists(); // New owner cannot already have an active identity

        _identityNFTIds[newOwner] = tokenId;
        _identityOwners[tokenId] = newOwner; // Owner can change on recovery
        _activeNFTs[tokenId] = true; // Reactivate the SBNFT

        emit IdentityRecovered(tokenId, newOwner);
    }

    /**
     * @notice INTERNAL - Generates a dynamic JSON metadata URI for a given SBNFT.
     *         This URI includes the SBNFT's name, description, an image link, and attributes
     *         reflecting its current archetype and unlocked traits.
     *         This function simulates dynamic metadata often handled by off-chain services.
     * @param tokenId The ID of the SBNFT.
     * @return A Base64-encoded data URI containing the JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert IdentityDoesNotExist();

        address owner = _identityOwners[tokenId];
        string memory currentArchetype = _calculateCurrentArchetype(owner);
        bytes32[] memory currentTraitIds = new bytes32[](_allTraitIds.length);
        uint256 traitCount = 0;

        for(uint256 i = 0; i < _allTraitIds.length; i++) {
            if (_identityTraits[tokenId][_allTraitIds[i]]) {
                currentTraitIds[traitCount] = _allTraitIds[i];
                traitCount++;
            }
        }

        // Build the JSON string for traits
        string memory traitsJson = "[";
        for (uint256 i = 0; i < traitCount; i++) {
            string memory traitName = _traits[currentTraitIds[i]].name;
            traitsJson = string.concat(traitsJson, '{"trait_type": "Identity Trait", "value": "', traitName, '"}');
            if (i < traitCount - 1) {
                traitsJson = string.concat(traitsJson, ",");
            }
        }
        traitsJson = string.concat(traitsJson, "]");

        // Assemble the full JSON metadata string
        string memory json = string.concat(
            '{"name": "AuraGenesis Identity #', tokenId.toString(),
            '", "description": "Dynamic digital identity for ', owner.toHexString(),
            '", "image": "', _baseTokenURI, tokenId.toString(), '.svg', // Link to a dynamic image service
            '", "attributes": [',
            '{"trait_type": "Archetype", "value": "', currentArchetype, '"},',
            traitsJson,
            ']}'
        );

        // Encode the JSON string to Base64 and prefix with data URI scheme
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }


    // VI. Reputation & Trait Progression (6 external/public, 1 internal)

    /**
     * @notice Returns the current reputation scores across all configured categories for a user.
     * @param user The address of the user.
     * @return Two arrays: one with `bytes32` reputation types, and one with their corresponding scores.
     */
    function getReputationScores(address user) external view returns (bytes32[] memory, uint256[] memory) {
        if (!_exists(_identityNFTIds[user])) revert IdentityDoesNotExist();

        // For demo purposes, assumes a few common reputation types.
        // In a real system, these would be managed by an array of all defined types.
        bytes32[] memory repTypes = new bytes32[](3);
        repTypes[0] = keccak256(abi.encodePacked("Engagement"));
        repTypes[1] = keccak256(abi.encodePacked("Reliability"));
        repTypes[2] = keccak256(abi.encodePacked("Creativity"));

        uint256[] memory scores = new uint256[](repTypes.length);
        for (uint256 i = 0; i < repTypes.length; i++) {
            scores[i] = _reputationScores[user].scores[repTypes[i]];
        }
        return (repTypes, scores);
    }

    /**
     * @notice Allows whitelisted oracles to submit attestations, updating the target user's reputation.
     *         Each attestation is uniquely identified by `attestationHash`.
     * @param targetUser The address whose reputation is being attested.
     * @param attestationType The type of reputation being attested (e.g., keccak256("Engagement")).
     * @param value The raw value of the attestation (will be weighted).
     * @param attestationHash A unique hash identifying this specific attestation event.
     */
    function submitAttestation(address targetUser, bytes32 attestationType, uint256 value, bytes32 attestationHash) external onlyOracle {
        if (!_exists(_identityNFTIds[targetUser])) revert IdentityDoesNotExist();
        if (_attestations[attestationHash].oracle != address(0)) revert IdentityAlreadyExists(); // Attestation with this hash already exists

        _attestations[attestationHash] = Attestation({
            oracle: msg.sender,
            targetUser: targetUser,
            attestationType: attestationType,
            value: value,
            timestamp: block.timestamp,
            disputed: false,
            resolved: false,
            originalHash: attestationHash
        });

        _processAttestation(targetUser, attestationType, value);
        emit AttestationSubmitted(msg.sender, targetUser, attestationType, value, attestationHash);
    }

    /**
     * @notice Determines and returns the user's current 'archetype' string based on their reputation distribution.
     * @param user The address of the user.
     * @return The string name of the user's current archetype.
     */
    function getArchetype(address user) external view onlyActiveIdentity(user) returns (string memory) {
        return _calculateCurrentArchetype(user);
    }

    /**
     * @notice Shows the user's progress towards unlocking a specific trait.
     * @param user The address of the user.
     * @param traitId The ID of the trait.
     * @return Three arrays: `reputationTypes` involved, `currentScores` for those types, and their `thresholds`.
     */
    function getTraitProgression(address user, bytes32 traitId) external view onlyActiveIdentity(user) returns (bytes32[] memory, uint256[] memory, uint256[] memory) {
        if (_traits[traitId].name.length == 0) revert InvalidTraitId();

        TraitUnlockCondition[] storage conditions = _traitUnlockConditions[traitId];
        bytes32[] memory repTypes = new bytes32[](conditions.length);
        uint256[] memory currentScores = new uint256[](conditions.length);
        uint256[] memory thresholds = new uint256[](conditions.length);

        for (uint256 i = 0; i < conditions.length; i++) {
            repTypes[i] = conditions[i].reputationType;
            currentScores[i] = _reputationScores[user].scores[conditions[i].reputationType];
            thresholds[i] = conditions[i].threshold;
        }
        return (repTypes, currentScores, thresholds);
    }

    /**
     * @notice Verifies if a user meets the requirements to unlock a given trait.
     * @param user The address of the user.
     * @param traitId The ID of the trait.
     * @return True if the user is eligible for the trait and hasn't claimed it, false otherwise.
     */
    function checkTraitEligibility(address user, bytes32 traitId) public view onlyActiveIdentity(user) returns (bool) {
        if (_traits[traitId].name.length == 0) revert InvalidTraitId();
        uint256 tokenId = _identityNFTIds[user];
        if (_identityTraits[tokenId][traitId]) return false; // Already claimed

        return _checkTraitConditions(user, traitId);
    }

    /**
     * @notice Allows an eligible user (or their delegate) to claim and apply a new trait to their SBNFT.
     * @param tokenId The ID of the user's SBNFT.
     * @param traitId The ID of the trait to claim.
     */
    function claimTraitUpgrade(uint256 tokenId, bytes32 traitId) external onlyIdentityOwner(tokenId) onlySelfOrDelegated(_identityOwners[tokenId], DELEGATE_CLAIM_TRAIT) {
        address user = _identityOwners[tokenId];
        if (!_exists(tokenId)) revert IdentityDoesNotExist();
        if (_identityTraits[tokenId][traitId]) revert TraitAlreadyClaimed(); // Ensure trait isn't already claimed
        if (!_checkTraitConditions(user, traitId)) revert TraitConditionNotMet(); // Check eligibility

        _identityTraits[tokenId][traitId] = true; // Mark trait as active for the SBNFT
        emit TraitUnlocked(tokenId, traitId);
    }

    /**
     * @notice INTERNAL - Processes an attestation by updating the user's reputation scores.
     *         Applies configured weights to the attestation value.
     * @param user The address of the user whose reputation is being updated.
     * @param attestationType The type of attestation.
     * @param value The raw value of the attestation.
     */
    function _processAttestation(address user, bytes32 attestationType, uint256 value) internal {
        uint256 weightedValue = value;
        // Apply weight if configured; if weight is 0 or not set, default to a multiplier of 1
        if (_attestationTypeWeights[attestationType] > 0) {
            weightedValue = value * _attestationTypeWeights[attestationType];
        } else if (_attestationTypeWeights[attestationType] == 0) {
             // If explicitly set to 0, it means no contribution. Or if not set at all.
             // For simplicity, we'll default to 1x if no specific weight is found/set.
             weightedValue = value;
        }


        _reputationScores[user].scores[attestationType] += weightedValue;
        _reputationScores[user].lastUpdated = block.timestamp;
        emit ReputationUpdated(user, attestationType, _reputationScores[user].scores[attestationType]);

        // Trait unlock checks are handled by `claimTraitUpgrade` which calls `_checkTraitConditions`.
    }


    // III. Oracle & Admin Management (5 external/public)

    /**
     * @notice Adds a new address to the list of approved attestor oracles.
     *         Only the contract owner can call this function.
     * @param oracleAddress The address of the new oracle.
     */
    function addAttestationOracle(address oracleAddress) external onlyOwner {
        _isAttestationOracle[oracleAddress] = true;
        emit OracleAdded(oracleAddress);
    }

    /**
     * @notice Removes an address from the list of approved attestor oracles.
     *         Only the contract owner can call this function.
     * @param oracleAddress The address of the oracle to remove.
     */
    function removeAttestationOracle(address oracleAddress) external onlyOwner {
        _isAttestationOracle[oracleAddress] = false;
        emit OracleRemoved(oracleAddress);
    }

    /**
     * @notice Sets the impact weight for a specific attestation type on reputation scores.
     *         For example, a weight of 2 means the attestation value is doubled.
     *         Only the contract owner can call this function.
     * @param attestationType The ID of the attestation type (e.g., keccak256("Engagement")).
     * @param weight The multiplier for the attestation's value.
     */
    function setAttestationTypeWeight(bytes32 attestationType, uint256 weight) external onlyOwner {
        _attestationTypeWeights[attestationType] = weight;
        emit AttestationTypeWeightSet(attestationType, weight);
    }

    /**
     * @notice Defines a new trait and its unlock condition(s).
     *         Multiple conditions can be added for a single trait over time.
     *         Only the contract owner can call this function.
     * @param traitId The unique ID of the trait (e.g., keccak256("Verified")).
     * @param name The human-readable name of the trait.
     * @param description A description of the trait.
     * @param imgURI An image URI associated with the trait.
     * @param reputationType The specific reputation type required for this condition.
     * @param threshold The minimum score required for `reputationType` to meet this condition.
     */
    function setTraitUnlockCondition(
        bytes32 traitId,
        string memory name,
        string memory description,
        string memory imgURI,
        bytes32 reputationType,
        uint256 threshold
    ) external onlyOwner {
        if (_traits[traitId].name.length == 0) { // If it's a completely new trait ID
            _allTraitIds.push(traitId); // Add to the list of all trait IDs
        }

        _traits[traitId] = Trait({
            name: name,
            description: description,
            imgURI: imgURI,
            active: true // New traits are active by default
        });

        // Add this specific condition to the trait's conditions array
        _traitUnlockConditions[traitId].push(TraitUnlockCondition({
            reputationType: reputationType,
            threshold: threshold
        }));

        emit TraitUnlockConditionSet(traitId, name, reputationType, threshold);
    }

    /**
     * @notice Configures the reputation ratio requirements for an archetype.
     *         Archetypes define a user's identity based on the balance of their reputation types.
     *         Ratios are expressed as `value * 10000` (e.g., 3000 for 30%).
     *         Only the contract owner can call this function.
     * @param archetypeId The unique ID of the archetype (e.g., 1, 2, 3...).
     * @param name The human-readable name of the archetype (e.g., "Builder", "Community Leader").
     * @param reputationTypes An array of `bytes32` reputation types.
     * @param minRatios An array of minimum ratios for each corresponding `reputationType`.
     * @param maxRatios An array of maximum ratios for each corresponding `reputationType`.
     */
    function setArchetypeCondition(
        uint256 archetypeId,
        string memory name,
        bytes32[] memory reputationTypes,
        uint256[] memory minRatios, // e.g., 3000 for 30%
        uint256[] memory maxRatios  // e.g., 6000 for 60%
    ) external onlyOwner {
        // Validate input arrays
        if (reputationTypes.length != minRatios.length || reputationTypes.length != maxRatios.length) {
            revert InvalidReputationRatios();
        }
        for (uint256 i = 0; i < minRatios.length; i++) {
            if (minRatios[i] > maxRatios[i] || maxRatios[i] > 10000) { // Ratios must be between 0 and 10000 (0%-100%)
                revert InvalidReputationRatios();
            }
        }
        
        // Ensure new archetype IDs are assigned sequentially
        if (_archetypeNames[archetypeId].length == 0) { // If it's a completely new archetype ID
            if (archetypeId != _nextArchetypeId) revert InvalidArchetypeId(); // Must be the next sequential ID
            _nextArchetypeId++; // Increment for the next new archetype
        }

        _archetypeConditions[archetypeId] = ArchetypeCondition({
            reputationTypes: reputationTypes,
            minRatios: minRatios,
            maxRatios: maxRatios
        });
        _archetypeNames[archetypeId] = name; // Store the human-readable name
        emit ArchetypeConditionSet(archetypeId, name);
    }


    // IV. Delegation & Privacy (4 external/public)

    /**
     * @notice Allows an SBNFT owner to delegate specific control functions to another address.
     *         Permissions are granted via a `functionMask` bitmask.
     * @param delegatee The address to which permissions are being delegated.
     * @param functionMask A bitmask representing the functions to delegate (e.g., `DELEGATE_CHALLENGE_ATTESTATION`).
     */
    function delegateIdentityFunction(address delegatee, uint256 functionMask) external onlyActiveIdentity(msg.sender) {
        _delegations[msg.sender][delegatee] = functionMask;
        emit DelegateAssigned(msg.sender, delegatee, functionMask);
    }

    /**
     * @notice Revokes all delegated permissions for a specific address from the caller's identity.
     * @param delegatee The address whose delegations are to be revoked.
     */
    function revokeDelegate(address delegatee) external onlyActiveIdentity(msg.sender) {
        delete _delegations[msg.sender][delegatee];
        emit DelegateRevoked(msg.sender, delegatee);
    }

    /**
     * @notice Returns the bitmask of delegated functions for a specific delegatee from a given owner.
     * @param owner The address of the SBNFT owner.
     * @param delegatee The address of the potential delegate.
     * @return A `uint256` bitmask representing the delegated functions.
     */
    function getDelegatedFunctions(address owner, address delegatee) external view returns (uint256) {
        return _delegations[owner][delegatee];
    }

    /**
     * @notice Allows an SBNFT owner to link a privacy-preserving hash (e.g., a ZK proof commitment)
     *         to their identity. This hash can represent off-chain verified data without revealing its content.
     * @param tokenId The ID of the SBNFT.
     * @param profileHash A `bytes32` hash representing off-chain identity data.
     */
    function updateIdentityProfileHash(uint256 tokenId, bytes32 profileHash) external onlyIdentityOwner(tokenId) {
        _identityProfileHashes[tokenId] = profileHash;
        emit IdentityProfileHashUpdated(tokenId, profileHash);
    }


    // V. Dispute System (3 external/public)

    /**
     * @notice Allows a user (or their delegate) to challenge a specific attestation made against them.
     *         The attestation will then enter a dispute phase, preventing further resolution until voted upon.
     * @param attestationHash The unique hash of the attestation being challenged.
     * @param reason A string explaining the reason for the challenge.
     */
    function challengeAttestation(bytes32 attestationHash, string memory reason) external {
        Attestation storage att = _attestations[attestationHash];
        if (att.oracle == address(0)) revert NoAttestationFound(); // Attestation must exist
        
        // Ensure caller is the target user OR a delegate with `DELEGATE_CHALLENGE_ATTESTATION` permission
        if (att.targetUser != msg.sender && (_delegations[att.targetUser][msg.sender] & DELEGATE_CHALLENGE_ATTESTATION) == 0) {
            revert NotAuthorized();
        }

        if (att.disputed) revert ChallengeInProgress(); // Cannot challenge an attestation already under dispute

        att.disputed = true; // Mark attestation as disputed
        _attestationChallenges[attestationHash] = AttestationChallenge({
            attestationHash: attestationHash,
            challenger: msg.sender,
            reason: reason,
            challengeTimestamp: block.timestamp,
            totalVotes: 0,
            approvedVotes: 0,
            rejectedVotes: 0,
            resolved: false,
            approvedByMajority: false
        });
        emit AttestationChallenged(attestationHash, msg.sender);
    }

    /**
     * @notice Allows whitelisted oracles to vote on a challenged attestation's validity.
     *         Oracles vote to either `approve` the challenge (meaning the original attestation was false)
     *         or reject it (meaning the original attestation was true).
     * @param attestationHash The hash of the attestation challenge to vote on.
     * @param approve True to approve the challenge (attestation false), false to reject (attestation true).
     */
    function voteOnAttestationChallenge(bytes32 attestationHash, bool approve) external onlyOracle {
        AttestationChallenge storage challenge = _attestationChallenges[attestationHash];
        if (challenge.challenger == address(0)) revert NoActiveChallenge(); // No challenge for this hash
        if (challenge.resolved) revert ChallengeNotResolved(); // Challenge already resolved
        if (challenge.hasVoted[msg.sender]) revert AlreadyVoted(); // Oracle already voted

        challenge.hasVoted[msg.sender] = true;
        challenge.totalVotes++;
        if (approve) {
            challenge.approvedVotes++; // Vote to support the challenge (attestation is considered invalid)
        } else {
            challenge.rejectedVotes++; // Vote against the challenge (attestation is considered valid)
        }
        emit AttestationChallengeVoted(attestationHash, msg.sender, approve);
    }

    /**
     * @notice Resolves a challenged attestation based on oracle votes.
     *         If the challenge is approved by a majority, the original reputation change
     *         from the attestation is reverted. Only the contract owner can finalize resolution.
     * @param attestationHash The hash of the attestation challenge to resolve.
     */
    function resolveAttestationChallenge(bytes32 attestationHash) external onlyOwner { // Only owner can finalize resolution
        AttestationChallenge storage challenge = _attestationChallenges[attestationHash];
        if (challenge.challenger == address(0)) revert NoActiveChallenge();
        if (challenge.resolved) revert ChallengeNotResolved();

        // Determine outcome: simple majority (approved votes > rejected votes)
        bool approvedByMajority = challenge.approvedVotes > challenge.rejectedVotes;
        challenge.approvedByMajority = approvedByMajority;
        challenge.resolved = true; // Mark challenge as resolved

        Attestation storage att = _attestations[attestationHash];
        bool reputationReverted = false;

        if (approvedByMajority) {
            // If the challenge was approved, revert the reputation change caused by the original attestation.
            uint256 currentScore = _reputationScores[att.targetUser].scores[att.attestationType];
            uint256 weightedValue = att.value;
            // Recalculate the original weighted value to subtract correctly
            if (_attestationTypeWeights[att.attestationType] > 0) {
                weightedValue = att.value * _attestationTypeWeights[att.attestationType];
            } else {
                weightedValue = att.value; // Default weight of 1
            }

            if (currentScore >= weightedValue) {
                _reputationScores[att.targetUser].scores[att.attestationType] = currentScore - weightedValue;
                reputationReverted = true;
            } else {
                _reputationScores[att.targetUser].scores[att.attestationType] = 0; // Prevent underflow; cap at 0
                reputationReverted = true;
            }
            emit ReputationUpdated(att.targetUser, att.attestationType, _reputationScores[att.targetUser].scores[att.attestationType]);
        }
        att.resolved = true; // Mark original attestation as having gone through dispute resolution

        emit AttestationChallengeResolved(attestationHash, approvedByMajority, reputationReverted);
    }


    // VI. Internal Helper Functions (3 internal)

    /**
     * @notice INTERNAL - Calculates the current archetype for a user based on their multi-dimensional reputation scores.
     *         It iterates through defined archetype conditions to find a matching profile.
     * @param user The address of the user.
     * @return The string name of the calculated archetype. Returns "Novice" if no reputation, "Explorer" if no conditions match.
     */
    function _calculateCurrentArchetype(address user) internal view returns (string memory) {
        uint256 totalReputation = 0;
        // For accurate total, iterate through all known reputation types.
        // For simplicity in this demo, hardcode a few common ones assumed to exist.
        bytes32[] memory knownReputationTypes = new bytes32[](3);
        knownReputationTypes[0] = keccak256(abi.encodePacked("Engagement"));
        knownReputationTypes[1] = keccak256(abi.encodePacked("Reliability"));
        knownReputationTypes[2] = keccak256(abi.encodePacked("Creativity"));

        for (uint256 i = 0; i < knownReputationTypes.length; i++) {
            totalReputation += _reputationScores[user].scores[knownReputationTypes[i]];
        }

        if (totalReputation == 0) return "Novice"; // Default for users with no reputation

        // Iterate through all defined archetypes (by sequential ID) to find a match
        for (uint256 i = 1; i < _nextArchetypeId; i++) {
            ArchetypeCondition storage condition = _archetypeConditions[i];
            if (condition.reputationTypes.length == 0) continue; // Skip unconfigured archetypes

            bool matches = true;
            for (uint256 j = 0; j < condition.reputationTypes.length; j++) {
                bytes32 repType = condition.reputationTypes[j];
                uint256 currentScore = _reputationScores[user].scores[repType];
                // Calculate current ratio, multiplied by 10000 to work with integer arithmetic
                uint256 currentRatio = (currentScore * 10000) / totalReputation; 

                if (currentRatio < condition.minRatios[j] || currentRatio > condition.maxRatios[j]) {
                    matches = false; // A condition is not met for this archetype
                    break;
                }
            }
            if (matches) {
                return _archetypeNames[i]; // Found a matching archetype
            }
        }
        return "Explorer"; // Default if no specific archetype conditions are met
    }

    /**
     * @notice INTERNAL - Checks if all defined conditions for a specific trait are met by a user.
     * @param user The address of the user.
     * @param traitId The ID of the trait.
     * @return True if all conditions for the trait are met, false otherwise.
     */
    function _checkTraitConditions(address user, bytes32 traitId) internal view returns (bool) {
        TraitUnlockCondition[] storage conditions = _traitUnlockConditions[traitId];
        if (conditions.length == 0) return false; // No conditions defined for this trait

        for (uint256 i = 0; i < conditions.length; i++) {
            if (_reputationScores[user].scores[conditions[i].reputationType] < conditions[i].threshold) {
                return false; // At least one condition is not met
            }
        }
        return true; // All conditions are met
    }

    /**
     * @notice INTERNAL - Retrieves a specific reputation score for a user.
     * @param user The address of the user.
     * @param repType The type of reputation to retrieve.
     * @return The score for the specified reputation type.
     */
    function _getReputationScore(address user, bytes32 repType) internal view returns (uint256) {
        return _reputationScores[user].scores[repType];
    }
}
```