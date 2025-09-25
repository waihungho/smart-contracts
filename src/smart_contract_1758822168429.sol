The smart contract presented here, **"Chronos Protocol: Adaptive Identity & Future-State Manifestation"**, is designed as a novel framework for on-chain identity evolution, reputation building, and personal commitment tracking. It aims to foster a system where users can create dynamic digital identities, commit to future goals (manifestations), and have their achievements and traits attested by the community, influencing their evolving on-chain persona.

---

### Chronos Protocol: Adaptive Identity & Future-State Manifestation

**Outline and Function Summary:**

This contract manages a unique system of dynamic identities, a multi-faceted reputation system, and a mechanism for users to stake on and verify their future commitments, leveraging time-based mechanics and oracle integrations.

**I. Core Identity Management:**
*   `registerIdentity`: Allows a user to create a new, unique identity.
*   `getIdentityDetails`: Retrieves all details for a given identity ID.
*   `updateIdentityName`: Allows an identity owner to change their identity's display name.
*   `freezeIdentity`: Permits an identity owner to temporarily suspend their identity's active participation.
*   `unfreezeIdentity`: Allows an owner to reactivate a frozen identity.
*   `deactivateIdentity`: Provides a mechanism for an owner to permanently deactivate their identity.
*   `transferIdentityOwnership`: Enables the secure transfer of an identity's ownership to a new address.

**II. Reputation, Traits & Social Attestation:**
*   `awardReputation`: Protocol owner awards reputation points to an identity.
*   `penalizeReputation`: Protocol owner deducts reputation points from an identity.
*   `addTraitTag`: Allows an identity owner to add a self-declared trait to their profile.
*   `removeTraitTag`: Allows an identity owner to remove a trait.
*   `attestIdentityTrait`: Enables another identity to vouch for the presence of a specific trait in another, earning karma.
*   `sendKarma`: Facilitates peer-to-peer transfer of internal "karma points" between identities.

**III. Manifestation (Future-State Commitment) System:**
*   `proposeManifestation`: Users commit to a future goal by providing a description hash, a target date, and staking value.
*   `getManifestationDetails`: Retrieves the details of a specific manifestation.
*   `fulfillManifestation`: Allows an identity owner to claim successful fulfillment of their manifestation.
*   `challengeManifestationFulfillment`: Enables any observer to challenge a claimed manifestation fulfillment, requiring a stake.
*   `resolveManifestationChallenge`: The protocol owner or designated oracle resolves a disputed manifestation, distributing/slashing stakes.
*   `claimManifestationStake`: Allows the identity owner to claim their stake back (and potential rewards) upon successful and unchallenged fulfillment.
*   `claimFailedManifestationStake`: Allows reclaiming a portion of stake if a manifestation failed without challenge.

**IV. Discovery & Analytics:**
*   `discoverIdentitiesByTrait`: Finds identities possessing a specific trait and meeting a minimum reputation score.
*   `discoverManifestationsByTimeframe`: Lists manifestations scheduled or fulfilled within a given time range.
*   `getIdentitiesByOwner`: Retrieves all identity IDs owned by a specific address.

**V. Protocol Governance & Maintenance:**
*   `setProtocolFee`: Sets the fee percentage for certain protocol operations.
*   `withdrawProtocolFees`: Allows the contract owner to withdraw accumulated protocol fees.
*   `setOracleAddress`: Configures the address of an external oracle service for specific verification tasks.
*   `updateMinimumCommitmentStake`: Adjusts the minimum ETH/token stake required for new manifestations.
*   `configureTraitAttestationThreshold`: Sets the minimum number of attestations required for a trait to be considered "community-verified."
*   `emergencyPause`: Pauses critical contract functions in case of an emergency.
*   `emergencyUnpause`: Unpauses the contract's functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Chronos Protocol: Adaptive Identity & Future-State Manifestation
/// @author Your Name/Pseudonym
/// @notice This contract provides a decentralized framework for dynamic identity management,
///         reputation tracking, and on-chain future-state commitments (manifestations).
///         It features a unique combination of time-based mechanics, social attestation,
///         and oracle integration for robust verification.

contract ChronosProtocol is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums ---
    enum ManifestationStatus {
        Pending,        // Commitment is active, target date not yet reached or claimed
        Fulfilled,      // Claimed fulfilled, awaiting challenge period or unchallenged
        Failed,         // Target date passed without fulfillment, or challenged & failed
        Challenged,     // Fulfillment is disputed, awaiting resolution
        Resolved        // Challenge has been resolved (status set to Fulfilled or Failed)
    }

    // --- Structs ---

    /// @dev Represents a unique on-chain identity for a user.
    struct Identity {
        address owner;
        uint256 id;
        string name;
        uint256 creationTimestamp;
        uint256 reputationScore;          // General reputation points
        mapping(string => bool) traitTags; // Self-declared or attested traits (e.g., "Innovator", "Collaborator")
        mapping(bytes32 => bool) activeManifestations; // Hash of active commitments
        bool isFrozen;                    // Temporary suspension by owner
        bool isActive;                    // Permanent deactivation
        uint256 lastInteractionTimestamp; // Timestamp of last significant interaction
        uint256 karmaPoints;              // Points gained from positive peer interactions
        mapping(string => uint256) traitAttestations; // How many times a specific trait has been attested
    }

    /// @dev Represents a user's commitment to a future action or state.
    struct Manifestation {
        bytes32 manifestationId;           // Unique hash of its details
        uint256 identityId;
        uint256 targetTimestamp;           // Target date/time for fulfillment
        bytes32 descriptionHash;           // IPFS hash or similar for detailed description
        uint256 commitmentValue;           // Value staked by the committer
        uint256 challengerStake;           // Value staked by a challenger, if any
        bytes32 fulfillmentOracleId;       // Identifier for an oracle service for verification (optional)
        ManifestationStatus status;
        uint256 challengeDeadline;         // Timestamp by which a challenge must be resolved
        address currentChallenger;         // Address of the active challenger
        bytes32 proofHash;                 // IPFS hash of proof submitted for fulfillment
        uint256 fulfilledTimestamp;        // Timestamp when fulfillment was claimed
    }

    // --- State Variables ---

    uint256 private _nextIdentityId;
    mapping(uint256 => Identity) public identities;
    mapping(address => uint256[]) public identityIdsByOwner; // For quick lookup of an owner's identities
    mapping(uint256 => bytes32[]) public manifestationsByIdentity; // For quick lookup of an identity's manifestations
    mapping(bytes32 => Manifestation) public manifestations; // manifestationId => Manifestation

    uint256 public protocolFeeBasisPoints; // e.g., 500 for 5%
    uint256 public totalProtocolFees;
    uint256 public minimumCommitmentStake; // Minimum ETH required to propose a manifestation

    mapping(bytes32 => address) public oracleAddresses; // oracleId (bytes32) => oracleContractAddress
    mapping(string => uint256) public traitAttestationThresholds; // trait => min_attestations_for_verified

    // --- Events ---

    event IdentityRegistered(uint256 indexed identityId, address indexed owner, string name, uint256 timestamp);
    event IdentityUpdated(uint256 indexed identityId, string newName, uint256 timestamp);
    event IdentityFrozen(uint256 indexed identityId, address indexed owner, uint256 timestamp);
    event IdentityUnfrozen(uint256 indexed identityId, address indexed owner, uint256 timestamp);
    event IdentityDeactivated(uint256 indexed identityId, address indexed owner, uint256 timestamp);
    event IdentityOwnershipTransferred(uint256 indexed identityId, address indexed oldOwner, address indexed newOwner, uint256 timestamp);

    event ReputationAwarded(uint256 indexed identityId, uint256 amount, uint256 newScore);
    event ReputationPenalized(uint256 indexed identityId, uint256 amount, uint256 newScore);
    event TraitAdded(uint256 indexed identityId, string trait);
    event TraitRemoved(uint256 indexed identityId, string trait);
    event TraitAttested(uint256 indexed identityId, address indexed attester, string trait, uint256 currentAttestations);
    event KarmaSent(uint256 indexed fromIdentityId, uint256 indexed toIdentityId, uint256 amount);

    event ManifestationProposed(bytes32 indexed manifestationId, uint256 indexed identityId, uint256 targetTimestamp, uint256 commitmentValue);
    event ManifestationFulfilled(bytes32 indexed manifestationId, uint256 indexed identityId, bytes32 proofHash, uint256 timestamp);
    event ManifestationChallenged(bytes32 indexed manifestationId, address indexed challenger, uint256 challengerStake, uint256 challengeDeadline);
    event ManifestationChallengeResolved(bytes32 indexed manifestationId, ManifestationStatus finalStatus, uint256 timestamp);
    event ManifestationStakeClaimed(bytes32 indexed manifestationId, address indexed beneficiary, uint256 amount, bool isChallenger);

    event ProtocolFeeUpdated(uint256 newFeeBasisPoints);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event OracleAddressSet(bytes32 indexed oracleId, address oracleAddress);
    event MinimumCommitmentStakeUpdated(uint256 newAmount);
    event TraitAttestationThresholdConfigured(string trait, uint256 threshold);

    // --- Modifiers ---

    modifier onlyIdentityOwner(uint256 _identityId) {
        require(identities[_identityId].owner == msg.sender, "CP: Not identity owner");
        _;
    }

    modifier onlyManifestationOwner(bytes32 _manifestationId) {
        require(
            manifestations[_manifestationId].identityId != 0 &&
            identities[manifestations[_manifestationId].identityId].owner == msg.sender,
            "CP: Not manifestation owner"
        );
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialFeeBasisPoints, uint256 _initialMinimumCommitmentStake) Ownable(msg.sender) {
        require(_initialFeeBasisPoints <= 10000, "CP: Fee basis points cannot exceed 100%");
        _nextIdentityId = 1; // Start identity IDs from 1
        protocolFeeBasisPoints = _initialFeeBasisPoints;
        minimumCommitmentStake = _initialMinimumCommitmentStake;
    }

    // --- I. Core Identity Management ---

    /// @notice Registers a new unique identity for the caller.
    /// @param _name The desired name for the new identity.
    /// @return The ID of the newly created identity.
    function registerIdentity(string calldata _name) external whenNotPaused returns (uint256) {
        require(bytes(_name).length > 0, "CP: Identity name cannot be empty");
        // Ensure name uniqueness (simple check, could be more robust with a mapping)
        // For simplicity, we are not enforcing strict global name uniqueness across all identities,
        // but rather focusing on unique identity IDs.
        
        uint256 newId = _nextIdentityId++;
        identities[newId] = Identity({
            owner: msg.sender,
            id: newId,
            name: _name,
            creationTimestamp: block.timestamp,
            reputationScore: 0,
            isFrozen: false,
            isActive: true,
            lastInteractionTimestamp: block.timestamp,
            karmaPoints: 0
        });
        identityIdsByOwner[msg.sender].push(newId);
        emit IdentityRegistered(newId, msg.sender, _name, block.timestamp);
        return newId;
    }

    /// @notice Retrieves the details of a specific identity.
    /// @param _identityId The ID of the identity to query.
    /// @return owner The address that owns the identity.
    /// @return name The display name of the identity.
    /// @return creationTimestamp The timestamp when the identity was created.
    /// @return reputationScore The current reputation score.
    /// @return isFrozen True if the identity is temporarily frozen.
    /// @return isActive True if the identity is active.
    /// @return lastInteractionTimestamp The timestamp of its last activity.
    /// @return karmaPoints The current karma points.
    function getIdentityDetails(uint256 _identityId)
        external
        view
        returns (
            address owner,
            string memory name,
            uint256 creationTimestamp,
            uint256 reputationScore,
            bool isFrozen,
            bool isActive,
            uint256 lastInteractionTimestamp,
            uint256 karmaPoints
        )
    {
        Identity storage id_ = identities[_identityId];
        require(id_.id != 0, "CP: Identity does not exist");
        return (
            id_.owner,
            id_.name,
            id_.creationTimestamp,
            id_.reputationScore,
            id_.isFrozen,
            id_.isActive,
            id_.lastInteractionTimestamp,
            id_.karmaPoints
        );
    }

    /// @notice Allows an identity owner to update the name of their identity.
    /// @param _identityId The ID of the identity to update.
    /// @param _newName The new desired name.
    function updateIdentityName(uint256 _identityId, string calldata _newName)
        external
        whenNotPaused
        onlyIdentityOwner(_identityId)
    {
        require(bytes(_newName).length > 0, "CP: New name cannot be empty");
        identities[_identityId].name = _newName;
        identities[_identityId].lastInteractionTimestamp = block.timestamp;
        emit IdentityUpdated(_identityId, _newName, block.timestamp);
    }

    /// @notice Allows an identity owner to temporarily freeze their identity.
    ///         A frozen identity cannot propose new manifestations or perform certain actions.
    /// @param _identityId The ID of the identity to freeze.
    function freezeIdentity(uint256 _identityId) external whenNotPaused onlyIdentityOwner(_identityId) {
        require(!identities[_identityId].isFrozen, "CP: Identity is already frozen");
        identities[_identityId].isFrozen = true;
        emit IdentityFrozen(_identityId, msg.sender, block.timestamp);
    }

    /// @notice Allows an identity owner to unfreeze their identity.
    /// @param _identityId The ID of the identity to unfreeze.
    function unfreezeIdentity(uint256 _identityId) external whenNotPaused onlyIdentityOwner(_identityId) {
        require(identities[_identityId].isFrozen, "CP: Identity is not frozen");
        identities[_identityId].isFrozen = false;
        emit IdentityUnfrozen(_identityId, msg.sender, block.timestamp);
    }

    /// @notice Allows an identity owner to permanently deactivate their identity.
    ///         Deactivated identities cannot be used for any protocol functions.
    /// @param _identityId The ID of the identity to deactivate.
    function deactivateIdentity(uint256 _identityId) external whenNotPaused onlyIdentityOwner(_identityId) {
        require(identities[_identityId].isActive, "CP: Identity is already inactive");
        identities[_identityId].isActive = false;
        // Further actions like clearing manifestations or reputation could be added.
        emit IdentityDeactivated(_identityId, msg.sender, block.timestamp);
    }

    /// @notice Allows the current owner of an identity to transfer its ownership to a new address.
    /// @param _identityId The ID of the identity to transfer.
    /// @param _newOwner The address of the new owner.
    function transferIdentityOwnership(uint256 _identityId, address _newOwner)
        external
        whenNotPaused
        onlyIdentityOwner(_identityId)
    {
        require(_newOwner != address(0), "CP: New owner cannot be zero address");
        require(_newOwner != msg.sender, "CP: New owner is already the current owner");

        address oldOwner = identities[_identityId].owner;
        identities[_identityId].owner = _newOwner;

        // Remove from old owner's list
        uint256[] storage oldOwnerIdentities = identityIdsByOwner[oldOwner];
        for (uint256 i = 0; i < oldOwnerIdentities.length; i++) {
            if (oldOwnerIdentities[i] == _identityId) {
                oldOwnerIdentities[i] = oldOwnerIdentities[oldOwnerIdentities.length - 1];
                oldOwnerIdentities.pop();
                break;
            }
        }
        // Add to new owner's list
        identityIdsByOwner[_newOwner].push(_identityId);

        emit IdentityOwnershipTransferred(_identityId, oldOwner, _newOwner, block.timestamp);
    }

    // --- II. Reputation, Traits & Social Attestation ---

    /// @notice Awards reputation points to an identity. Only callable by the contract owner.
    /// @param _identityId The ID of the identity to award points to.
    /// @param _amount The amount of reputation points to award.
    function awardReputation(uint256 _identityId, uint256 _amount) external onlyOwner whenNotPaused {
        require(identities[_identityId].id != 0, "CP: Identity does not exist");
        require(identities[_identityId].isActive, "CP: Identity is inactive");
        identities[_identityId].reputationScore = identities[_identityId].reputationScore.add(_amount);
        identities[_identityId].lastInteractionTimestamp = block.timestamp;
        emit ReputationAwarded(_identityId, _amount, identities[_identityId].reputationScore);
    }

    /// @notice Penalizes (deducts) reputation points from an identity. Only callable by the contract owner.
    /// @param _identityId The ID of the identity to penalize.
    /// @param _amount The amount of reputation points to deduct.
    function penalizeReputation(uint256 _identityId, uint256 _amount) external onlyOwner whenNotPaused {
        require(identities[_identityId].id != 0, "CP: Identity does not exist");
        require(identities[_identityId].isActive, "CP: Identity is inactive");
        identities[_identityId].reputationScore = identities[_identityId].reputationScore.sub(_amount, "CP: Reputation cannot go negative");
        identities[_identityId].lastInteractionTimestamp = block.timestamp;
        emit ReputationPenalized(_identityId, _amount, identities[_identityId].reputationScore);
    }

    /// @notice Allows an identity owner to add a self-declared trait to their profile.
    /// @param _identityId The ID of the identity.
    /// @param _trait The trait string (e.g., "Developer", "Designer").
    function addTraitTag(uint256 _identityId, string calldata _trait)
        external
        whenNotPaused
        onlyIdentityOwner(_identityId)
    {
        require(bytes(_trait).length > 0, "CP: Trait cannot be empty");
        require(!identities[_identityId].isFrozen, "CP: Identity is frozen");
        require(identities[_identityId].isActive, "CP: Identity is inactive");
        require(!identities[_identityId].traitTags[_trait], "CP: Trait already exists");
        identities[_identityId].traitTags[_trait] = true;
        identities[_identityId].lastInteractionTimestamp = block.timestamp;
        emit TraitAdded(_identityId, _trait);
    }

    /// @notice Allows an identity owner to remove a trait from their profile.
    /// @param _identityId The ID of the identity.
    /// @param _trait The trait string to remove.
    function removeTraitTag(uint256 _identityId, string calldata _trait)
        external
        whenNotPaused
        onlyIdentityOwner(_identityId)
    {
        require(identities[_identityId].traitTags[_trait], "CP: Trait does not exist");
        identities[_identityId].traitTags[_trait] = false; // Soft delete
        identities[_identityId].lastInteractionTimestamp = block.timestamp;
        // Optionally, reset attestation count for this trait.
        emit TraitRemoved(_identityId, _trait);
    }

    /// @notice Allows one identity to attest to a specific trait of another identity.
    ///         This increases the `traitAttestations` count for the target identity's trait.
    /// @param _identityId The ID of the identity whose trait is being attested.
    /// @param _trait The trait string being attested.
    function attestIdentityTrait(uint256 _identityId, string calldata _trait) external whenNotPaused {
        require(identities[_identityId].id != 0, "CP: Target identity does not exist");
        require(identities[_identityId].isActive, "CP: Target identity is inactive");
        // An identity cannot attest its own trait
        require(identities[_identityId].owner != msg.sender, "CP: Cannot attest your own trait");
        
        uint256 attesterIdentityId = 0; // Find attester's identity ID
        for(uint256 i = 0; i < identityIdsByOwner[msg.sender].length; i++) {
            if(identities[identityIdsByOwner[msg.sender][i]].isActive) {
                attesterIdentityId = identityIdsByOwner[msg.sender][i];
                break;
            }
        }
        require(attesterIdentityId != 0, "CP: Attester must have an active identity");
        require(!identities[attesterIdentityId].isFrozen, "CP: Attester identity is frozen");
        
        // Ensure the trait actually exists or is recognized
        require(identities[_identityId].traitTags[_trait], "CP: Target identity does not have this trait");

        identities[_identityId].traitAttestations[_trait]++;
        identities[_identityId].lastInteractionTimestamp = block.timestamp;
        
        // Optionally reward attester with Karma
        identities[attesterIdentityId].karmaPoints = identities[attesterIdentityId].karmaPoints.add(1);
        emit TraitAttested(_identityId, msg.sender, _trait, identities[_identityId].traitAttestations[_trait]);
        emit KarmaSent(attesterIdentityId, _identityId, 0); // Event to log karma gain as a side effect
    }

    /// @notice Allows one active identity to send karma points to another active identity.
    /// @param _fromIdentityId The ID of the sending identity.
    /// @param _toIdentityId The ID of the receiving identity.
    /// @param _amount The amount of karma points to send.
    function sendKarma(uint256 _fromIdentityId, uint256 _toIdentityId, uint256 _amount)
        external
        whenNotPaused
        onlyIdentityOwner(_fromIdentityId)
    {
        require(identities[_toIdentityId].id != 0, "CP: Recipient identity does not exist");
        require(identities[_toIdentityId].isActive, "CP: Recipient identity is inactive");
        require(!identities[_fromIdentityId].isFrozen, "CP: Sender identity is frozen");
        require(!identities[_toIdentityId].isFrozen, "CP: Recipient identity is frozen");
        require(_fromIdentityId != _toIdentityId, "CP: Cannot send karma to yourself");
        require(_amount > 0, "CP: Karma amount must be positive");
        require(identities[_fromIdentityId].karmaPoints >= _amount, "CP: Insufficient karma points");

        identities[_fromIdentityId].karmaPoints = identities[_fromIdentityId].karmaPoints.sub(_amount);
        identities[_toIdentityId].karmaPoints = identities[_toIdentityId].karmaPoints.add(_amount);
        identities[_fromIdentityId].lastInteractionTimestamp = block.timestamp;
        identities[_toIdentityId].lastInteractionTimestamp = block.timestamp;

        emit KarmaSent(_fromIdentityId, _toIdentityId, _amount);
    }


    // --- III. Manifestation (Future-State Commitment) System ---

    /// @notice Allows an identity owner to propose a new future-state manifestation.
    ///         Requires staking `minimumCommitmentStake` or more.
    /// @param _identityId The ID of the identity making the commitment.
    /// @param _targetTimestamp The target Unix timestamp by which the manifestation should be fulfilled.
    /// @param _descriptionHash IPFS hash (or similar) of the detailed manifestation description.
    /// @param _fulfillmentOracleId Optional ID for an oracle service that can verify fulfillment.
    /// @return The unique ID (hash) of the newly proposed manifestation.
    function proposeManifestation(
        uint256 _identityId,
        uint256 _targetTimestamp,
        bytes32 _descriptionHash,
        bytes32 _fulfillmentOracleId // Optional: can be 0x0
    ) external payable whenNotPaused onlyIdentityOwner(_identityId) returns (bytes32) {
        require(!identities[_identityId].isFrozen, "CP: Identity is frozen");
        require(identities[_identityId].isActive, "CP: Identity is inactive");
        require(_targetTimestamp > block.timestamp, "CP: Target timestamp must be in the future");
        require(msg.value >= minimumCommitmentStake, "CP: Insufficient commitment stake");
        require(_descriptionHash != bytes32(0), "CP: Description hash cannot be empty");

        bytes32 manifestationId = keccak256(
            abi.encodePacked(_identityId, _targetTimestamp, _descriptionHash, block.timestamp)
        );

        require(manifestations[manifestationId].identityId == 0, "CP: Manifestation ID collision (highly unlikely)");

        manifestations[manifestationId] = Manifestation({
            manifestationId: manifestationId,
            identityId: _identityId,
            targetTimestamp: _targetTimestamp,
            descriptionHash: _descriptionHash,
            commitmentValue: msg.value,
            challengerStake: 0,
            fulfillmentOracleId: _fulfillmentOracleId,
            status: ManifestationStatus.Pending,
            challengeDeadline: 0,
            currentChallenger: address(0),
            proofHash: bytes32(0),
            fulfilledTimestamp: 0
        });

        identities[_identityId].activeManifestations[manifestationId] = true;
        manifestationsByIdentity[_identityId].push(manifestationId);
        identities[_identityId].lastInteractionTimestamp = block.timestamp;

        emit ManifestationProposed(manifestationId, _identityId, _targetTimestamp, msg.value);
        return manifestationId;
    }

    /// @notice Retrieves the detailed information of a specific manifestation.
    /// @param _manifestationId The ID of the manifestation to query.
    /// @return identityId The ID of the identity that proposed the manifestation.
    /// @return targetTimestamp The target timestamp for fulfillment.
    /// @return descriptionHash The IPFS hash of the description.
    /// @return commitmentValue The staked value.
    /// @return fulfillmentOracleId The ID of the oracle for verification.
    /// @return status The current status of the manifestation.
    /// @return challengeDeadline The deadline for challenge resolution.
    /// @return currentChallenger The address of the current challenger.
    /// @return proofHash The IPFS hash of the proof of fulfillment.
    /// @return fulfilledTimestamp The timestamp of claimed fulfillment.
    function getManifestationDetails(bytes32 _manifestationId)
        external
        view
        returns (
            uint256 identityId,
            uint256 targetTimestamp,
            bytes32 descriptionHash,
            uint256 commitmentValue,
            bytes32 fulfillmentOracleId,
            ManifestationStatus status,
            uint256 challengeDeadline,
            address currentChallenger,
            bytes32 proofHash,
            uint256 fulfilledTimestamp
        )
    {
        Manifestation storage m = manifestations[_manifestationId];
        require(m.identityId != 0, "CP: Manifestation does not exist");
        return (
            m.identityId,
            m.targetTimestamp,
            m.descriptionHash,
            m.commitmentValue,
            m.fulfillmentOracleId,
            m.status,
            m.challengeDeadline,
            m.currentChallenger,
            m.proofHash,
            m.fulfilledTimestamp
        );
    }

    /// @notice Allows the owner of a manifestation to claim its fulfillment.
    ///         Can only be called after the target timestamp has passed or just before.
    /// @param _manifestationId The ID of the manifestation to fulfill.
    /// @param _proofHash IPFS hash (or similar) of the proof of fulfillment.
    function fulfillManifestation(bytes32 _manifestationId, bytes32 _proofHash)
        external
        whenNotPaused
        onlyManifestationOwner(_manifestationId)
    {
        Manifestation storage m = manifestations[_manifestationId];
        require(m.status == ManifestationStatus.Pending, "CP: Manifestation not in pending state");
        require(m.targetTimestamp <= block.timestamp.add(1 days), "CP: Cannot fulfill too early (1 day grace period)"); // Allow slight early claim
        require(_proofHash != bytes32(0), "CP: Proof hash cannot be empty");

        m.status = ManifestationStatus.Fulfilled;
        m.proofHash = _proofHash;
        m.fulfilledTimestamp = block.timestamp;
        identities[m.identityId].lastInteractionTimestamp = block.timestamp;

        // Set a challenge period (e.g., 7 days)
        m.challengeDeadline = block.timestamp.add(7 days);

        emit ManifestationFulfilled(_manifestationId, m.identityId, _proofHash, block.timestamp);
    }

    /// @notice Allows any active identity to challenge a claimed manifestation fulfillment.
    ///         Requires staking an amount equal to the original commitment value.
    /// @param _manifestationId The ID of the manifestation to challenge.
    function challengeManifestationFulfillment(bytes32 _manifestationId) external payable whenNotPaused nonReentrant {
        Manifestation storage m = manifestations[_manifestationId];
        require(m.identityId != 0, "CP: Manifestation does not exist");
        require(m.status == ManifestationStatus.Fulfilled, "CP: Manifestation not in fulfilled state");
        require(block.timestamp <= m.challengeDeadline, "CP: Challenge period has ended");
        require(m.currentChallenger == address(0), "CP: Manifestation already challenged");
        require(msg.value >= m.commitmentValue, "CP: Insufficient challenge stake (must match commitment)");

        // Ensure challenger has an active identity
        uint256 challengerIdentityId = 0;
        for(uint256 i = 0; i < identityIdsByOwner[msg.sender].length; i++) {
            if(identities[identityIdsByOwner[msg.sender][i]].isActive) {
                challengerIdentityId = identityIdsByOwner[msg.sender][i];
                break;
            }
        }
        require(challengerIdentityId != 0, "CP: Challenger must have an active identity");
        require(!identities[challengerIdentityId].isFrozen, "CP: Challenger identity is frozen");

        m.status = ManifestationStatus.Challenged;
        m.challengerStake = msg.value;
        m.currentChallenger = msg.sender;
        // Extend challenge deadline for resolution (e.g., 14 days for resolution)
        m.challengeDeadline = block.timestamp.add(14 days); 
        identities[challengerIdentityId].lastInteractionTimestamp = block.timestamp;

        emit ManifestationChallenged(_manifestationId, msg.sender, msg.value, m.challengeDeadline);
    }

    /// @notice Resolves a challenged manifestation. Only callable by the contract owner or designated oracle.
    /// @param _manifestationId The ID of the challenged manifestation.
    /// @param _isFulfilled True if the challenge outcome is that the manifestation was indeed fulfilled, false otherwise.
    function resolveManifestationChallenge(bytes32 _manifestationId, bool _isFulfilled) external onlyOwner whenNotPaused {
        Manifestation storage m = manifestations[_manifestationId];
        require(m.identityId != 0, "CP: Manifestation does not exist");
        require(m.status == ManifestationStatus.Challenged, "CP: Manifestation not in challenged state");
        // Check if an oracle is configured and caller is that oracle address, or if caller is contract owner
        if (m.fulfillmentOracleId != bytes32(0)) {
            require(msg.sender == oracleAddresses[m.fulfillmentOracleId], "CP: Not authorized oracle or contract owner");
        } else {
            require(msg.sender == owner(), "CP: Only contract owner can resolve without an assigned oracle");
        }
        require(block.timestamp <= m.challengeDeadline, "CP: Resolution deadline has passed");

        address originalOwner = identities[m.identityId].owner;
        address challenger = m.currentChallenger;

        uint256 totalStakes = m.commitmentValue.add(m.challengerStake);
        uint256 protocolFee = totalStakes.mul(protocolFeeBasisPoints).div(10000);
        totalProtocolFees = totalProtocolFees.add(protocolFee);

        uint256 remainingForDistribution = totalStakes.sub(protocolFee);

        if (_isFulfilled) {
            // Original committer wins: gets their stake + challenger's stake (minus fees)
            payable(originalOwner).transfer(remainingForDistribution);
            m.status = ManifestationStatus.Fulfilled;
            // Optionally, penalize challenger's reputation
            // penalizeReputation(identity ID of challenger, amount)
        } else {
            // Challenger wins: gets their stake + committer's stake (minus fees)
            payable(challenger).transfer(remainingForDistribution);
            m.status = ManifestationStatus.Failed;
            // Optionally, penalize original committer's reputation
            // penalizeReputation(m.identityId, amount)
        }

        m.currentChallenger = address(0);
        m.challengerStake = 0;
        m.challengeDeadline = 0; // Reset after resolution
        identities[m.identityId].activeManifestations[m.manifestationId] = false; // Mark as resolved
        identities[m.identityId].lastInteractionTimestamp = block.timestamp;

        emit ManifestationChallengeResolved(_manifestationId, m.status, block.timestamp);
    }

    /// @notice Allows the identity owner to claim their stake after successful and unchallenged fulfillment.
    /// @param _manifestationId The ID of the fulfilled manifestation.
    function claimManifestationStake(bytes32 _manifestationId) external whenNotPaused nonReentrant onlyManifestationOwner(_manifestationId) {
        Manifestation storage m = manifestations[_manifestationId];
        require(m.status == ManifestationStatus.Fulfilled, "CP: Manifestation not fulfilled");
        require(block.timestamp > m.challengeDeadline, "CP: Challenge period not over yet");
        require(m.commitmentValue > 0, "CP: Stake already claimed or never existed");

        uint256 amountToTransfer = m.commitmentValue;
        uint256 protocolFee = amountToTransfer.mul(protocolFeeBasisPoints).div(10000);
        totalProtocolFees = totalProtocolFees.add(protocolFee);
        amountToTransfer = amountToTransfer.sub(protocolFee);

        m.commitmentValue = 0; // Mark stake as claimed
        identities[m.identityId].activeManifestations[m.manifestationId] = false; // Mark as resolved
        identities[m.identityId].lastInteractionTimestamp = block.timestamp;

        payable(msg.sender).transfer(amountToTransfer);
        emit ManifestationStakeClaimed(_manifestationId, msg.sender, amountToTransfer, false);
    }

    /// @notice Allows the identity owner to claim back their stake (or a portion) if a manifestation
    ///         failed without being challenged, after its target timestamp has passed.
    ///         A small penalty may apply.
    /// @param _manifestationId The ID of the failed manifestation.
    function claimFailedManifestationStake(bytes32 _manifestationId) external whenNotPaused nonReentrant onlyManifestationOwner(_manifestationId) {
        Manifestation storage m = manifestations[_manifestationId];
        require(m.identityId != 0, "CP: Manifestation does not exist");
        require(m.status == ManifestationStatus.Pending, "CP: Manifestation not pending (already fulfilled, challenged, or resolved)");
        require(block.timestamp > m.targetTimestamp, "CP: Target timestamp not yet reached");
        require(m.commitmentValue > 0, "CP: Stake already claimed or never existed");

        // If no one fulfilled and no one challenged after target, it's failed implicitly.
        // Apply a penalty (e.g., 25% penalty for failure to fulfill)
        uint256 penaltyBasisPoints = 2500; // 25% penalty
        uint256 penaltyAmount = m.commitmentValue.mul(penaltyBasisPoints).div(10000);
        
        totalProtocolFees = totalProtocolFees.add(penaltyAmount); // Penalty goes to protocol
        uint256 amountToReturn = m.commitmentValue.sub(penaltyAmount);

        m.commitmentValue = 0; // Mark stake as claimed
        m.status = ManifestationStatus.Failed;
        identities[m.identityId].activeManifestations[m.manifestationId] = false; // Mark as resolved
        identities[m.identityId].lastInteractionTimestamp = block.timestamp;

        payable(msg.sender).transfer(amountToReturn);
        emit ManifestationStakeClaimed(_manifestationId, msg.sender, amountToReturn, false);
    }

    // --- IV. Discovery & Analytics ---

    /// @notice Discovers identities that possess a specific trait and meet a minimum reputation score.
    /// @param _trait The trait string to filter by.
    /// @param _minReputation The minimum reputation score required.
    /// @return An array of identity IDs matching the criteria.
    function discoverIdentitiesByTrait(string calldata _trait, uint256 _minReputation)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory matchingIds = new uint256[](_nextIdentityId); // Max possible size
        uint256 count = 0;
        // Iterate through all identities (could be optimized with more complex mappings)
        for (uint256 i = 1; i < _nextIdentityId; i++) {
            Identity storage id_ = identities[i];
            if (id_.id != 0 && id_.isActive && id_.traitTags[_trait] && id_.reputationScore >= _minReputation) {
                matchingIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingIds[i];
        }
        return result;
    }

    /// @notice Lists manifestations that are active or were fulfilled/failed within a given timeframe.
    /// @param _startTimestamp The start of the time range.
    /// @param _endTimestamp The end of the time range.
    /// @return An array of manifestation IDs within the specified timeframe.
    function discoverManifestationsByTimeframe(uint256 _startTimestamp, uint256 _endTimestamp)
        external
        view
        returns (bytes32[] memory)
    {
        // This function iterates through all manifestations, which can be gas-intensive
        // For a large number of manifestations, an off-chain indexer would be more practical.
        // This is illustrative of the discovery concept.

        bytes32[] memory matchingManifestations = new bytes32[](_nextIdentityId * 10); // Heuristic max size
        uint256 count = 0;

        for (uint256 i = 1; i < _nextIdentityId; i++) {
            for (uint256 j = 0; j < manifestationsByIdentity[i].length; j++) {
                bytes32 mId = manifestationsByIdentity[i][j];
                Manifestation storage m = manifestations[mId];

                bool inTimeframe = false;
                if (m.status == ManifestationStatus.Pending && m.targetTimestamp >= _startTimestamp && m.targetTimestamp <= _endTimestamp) {
                    inTimeframe = true;
                } else if (m.status == ManifestationStatus.Fulfilled && m.fulfilledTimestamp >= _startTimestamp && m.fulfilledTimestamp <= _endTimestamp) {
                    inTimeframe = true;
                } else if (m.status == ManifestationStatus.Failed && (m.fulfilledTimestamp == 0 ? m.targetTimestamp : m.fulfilledTimestamp) >= _startTimestamp && (m.fulfilledTimestamp == 0 ? m.targetTimestamp : m.fulfilledTimestamp) <= _endTimestamp) {
                    inTimeframe = true;
                }
                // Add more conditions for Challenged/Resolved if needed.

                if (inTimeframe) {
                    matchingManifestations[count++] = mId;
                }
            }
        }

        bytes32[] memory result = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingManifestations[i];
        }
        return result;
    }
    
    /// @notice Retrieves all identity IDs owned by a specific address.
    /// @param _owner The address to query.
    /// @return An array of identity IDs owned by `_owner`.
    function getIdentitiesByOwner(address _owner) external view returns (uint256[] memory) {
        return identityIdsByOwner[_owner];
    }


    // --- V. Protocol Governance & Maintenance ---

    /// @notice Sets the protocol fee basis points (e.g., 500 for 5%). Only callable by owner.
    /// @param _newFeeBasisPoints The new fee percentage in basis points (0-10000).
    function setProtocolFee(uint256 _newFeeBasisPoints) external onlyOwner whenNotPaused {
        require(_newFeeBasisPoints <= 10000, "CP: Fee basis points cannot exceed 100%");
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeUpdated(_newFeeBasisPoints);
    }

    /// @notice Allows the contract owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 amount = totalProtocolFees;
        require(amount > 0, "CP: No fees to withdraw");
        totalProtocolFees = 0;
        payable(msg.sender).transfer(amount);
        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }

    /// @notice Sets the address for a specific oracle service identified by its ID. Only callable by owner.
    /// @param _oracleId A unique identifier for the oracle service.
    /// @param _oracleAddress The blockchain address of the oracle contract or trusted off-chain reporter.
    function setOracleAddress(bytes32 _oracleId, address _oracleAddress) external onlyOwner whenNotPaused {
        require(_oracleId != bytes32(0), "CP: Oracle ID cannot be zero");
        require(_oracleAddress != address(0), "CP: Oracle address cannot be zero");
        oracleAddresses[_oracleId] = _oracleAddress;
        emit OracleAddressSet(_oracleId, _oracleAddress);
    }

    /// @notice Updates the minimum ETH/token stake required for proposing new manifestations. Only callable by owner.
    /// @param _newAmount The new minimum stake amount.
    function updateMinimumCommitmentStake(uint256 _newAmount) external onlyOwner whenNotPaused {
        minimumCommitmentStake = _newAmount;
        emit MinimumCommitmentStakeUpdated(_newAmount);
    }

    /// @notice Configures the minimum number of attestations required for a specific trait to be
    ///         considered "community-verified" or to unlock certain protocol features. Only callable by owner.
    /// @param _trait The trait string to configure.
    /// @param _minAttestations The new minimum attestation threshold.
    function configureTraitAttestationThreshold(string calldata _trait, uint256 _minAttestations) external onlyOwner whenNotPaused {
        require(bytes(_trait).length > 0, "CP: Trait cannot be empty");
        traitAttestationThresholds[_trait] = _minAttestations;
        emit TraitAttestationThresholdConfigured(_trait, _minAttestations);
    }

    /// @notice Pauses certain critical functions of the contract in an emergency. Only callable by owner.
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract's functions after an emergency. Only callable by owner.
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }
}
```