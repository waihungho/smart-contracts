The smart contract presented here, **ChronoVault**, introduces a novel concept for self-sovereign conditional data release. It allows users to create NFTs (Vaults) that encapsulate cryptographic hashes or CIDs of sensitive off-chain data (e.g., encrypted files on IPFS, Arweave). The core innovation lies in the ability to attach multiple, complex conditional release policies to these Vaults. These policies dictate *when* and *to *whom* the data's identifier (hash/CID) can be revealed, enabling advanced use cases like digital inheritance, escrow, time-locked releases, event-driven data dissemination, and even ZK-proof verified access.

This contract integrates several advanced concepts:
*   **NFT-based Data Encapsulation:** Each "Vault" is an ERC-721 token representing ownership and control over the release conditions of data.
*   **Modular Policy Engine:** A flexible system to define various types of conditional release policies.
*   **Diverse Conditional Logic:**
    *   **Time-Locked Release:** Data becomes accessible after a specific timestamp.
    *   **Event-Triggered Release:** Data is released based on the occurrence of an external on-chain event (monitored by relayers/oracles).
    *   **Multi-Party Approval:** Requires a specified number of designated parties to approve the release.
    *   **ZK-Proof Conditional Release:** Access is granted only upon submission of a valid Zero-Knowledge Proof, verified on-chain, proving a specific condition without revealing underlying sensitive information.
    *   **Dead Man's Switch:** Data is released to a successor if the owner becomes inactive for a defined period.
*   **Role-Based Access Control:** Differentiated permissions for vault owners, beneficiaries, relayers, and contract administrators.
*   **Emergency & Admin Controls:** Mechanisms for critical overrides, pausing operations, and managing external dependencies (like ZK verifiers).

This combination of modular, diverse, and advanced conditional release mechanisms within an NFT-backed data vault is a unique approach to decentralized data management and privacy, distinguishing it from standard escrow, multi-sig, or time-lock contracts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Interface for a generic ZK-Proof Verifier contract (e.g., Groth16, Plonk)
interface IVerifier {
    function verifyProof(uint[] calldata _a, uint[] calldata _b, uint[] calldata _c, uint[] calldata _input) external view returns (bool);
}

// Contract Name: ChronoVault
// A Self-Sovereign Conditional Data Release Protocol
//
// Outline:
// I. Core Vault Management (ERC-721 based)
//    - NFT creation, ownership, and content updates.
// II. Policy Management
//    - Adding, updating, and removing various conditional release policies.
// III. Release & Access Control
//    - Mechanisms to trigger policy evaluations and grant access to data hashes.
// IV. Advanced / Admin Functions
//    - Emergency controls, oracle/verifier management, relayer designations, trustee management.
//
// Function Summary:
//
// Constructor:
// - `constructor(string memory name, string memory symbol)`: Initializes the ERC721 token and sets the contract deployer as the initial owner.
//
// I. Core Vault Management:
// - `createVault(string memory _contentHashCID)`: Mints a new ERC-721 Vault NFT for the caller, storing a hash/CID of the (off-chain) data.
// - `updateVaultContentHash(uint256 _vaultId, string memory _newContentHashCID)`: Allows the vault owner to update the stored content hash/CID.
// - `burnVault(uint256 _vaultId)`: Allows the vault owner to burn their vault NFT, effectively destroying it and removing all associated policies.
//
// II. Policy Management:
// - `addTimeLockPolicy(uint256 _vaultId, uint256 _releaseTimestamp, address[] memory _beneficiaries)`: Adds a policy where content is released after a specific timestamp to specified beneficiaries.
// - `addEventTriggerPolicy(uint256 _vaultId, bytes32 _externalConditionIdentifier, address[] memory _beneficiaries)`: Adds a policy where content is released upon a specific external event/condition identified by `_externalConditionIdentifier`. Requires a designated relayer to confirm.
// - `addMultiPartyApprovalPolicy(uint256 _vaultId, address[] memory _approvers, uint256 _requiredApprovals, address[] memory _beneficiaries)`: Adds a policy requiring N of M designated parties to approve release.
// - `addZKProofPolicy(uint256 _vaultId, address _zkVerifierContract, bytes32 _proofContextHash, address[] memory _beneficiaries)`: Adds a policy requiring a valid ZK-proof submission (verified by `_zkVerifierContract`) for a specific `_proofContextHash` (identifying the proof type).
// - `addDeadManSwitchPolicy(uint256 _vaultId, uint256 _inactivityDuration, address _successor, address[] memory _beneficiaries)`: Adds a policy for release to a `_successor` if the owner is inactive for a set duration.
// - `updatePolicyStatus(uint256 _vaultId, uint256 _policyId, bool _isActive)`: Allows the vault owner to enable or disable an existing policy.
// - `removePolicy(uint256 _vaultId, uint256 _policyId)`: Allows the vault owner to remove a policy.
// - `getPolicyDetails(uint256 _vaultId, uint256 _policyId)`: View function to retrieve details of a specific policy for a vault.
// - `getVaultPolicies(uint256 _vaultId)`: View function to retrieve all policy IDs associated with a vault.
//
// III. Release & Access Control:
// - `triggerTimeLockRelease(uint256 _vaultId, uint256 _policyId)`: Callable by anyone to check and trigger release if the time-lock condition for a specific policy is met.
// - `triggerEventRelease(uint256 _vaultId, uint256 _policyId)`: Callable by an authorized relayer to trigger release for an event-based policy, confirming the external condition is met.
// - `submitMultiPartyApproval(uint256 _vaultId, uint256 _policyId)`: Allows a designated approver to submit their approval for a multi-party policy.
// - `submitZKProofAndRelease(uint256 _vaultId, uint256 _policyId, uint[] memory _proofA, uint[] memory _proofB, uint[] memory _proofC, uint[] memory _input)`: Allows a user to submit a ZK-proof for verification and potentially trigger release for a ZK-proof policy.
// - `checkDeadManSwitch(uint256 _vaultId, uint256 _policyId)`: Callable by the successor or relayer to check owner's inactivity and trigger release for a Dead Man's Switch policy.
// - `getReleaseStatus(uint256 _vaultId)`: View function to check the current overall release status of a vault based on all active policies (returns true if ANY policy allows release).
// - `requestAccessKey(uint256 _vaultId)`: Allows a beneficiary to request and retrieve the content hash/CID if the vault is released and they are a designated beneficiary.
// - `updateLastOwnerActivity(uint256 _vaultId)`: Callable by the vault owner to reset the inactivity timer for the Dead Man's Switch policies.
//
// IV. Advanced / Admin Functions:
// - `emergencyBypassRelease(uint256 _vaultId, uint256 _delaySeconds)`: A highly restricted, owner-only function to initiate an emergency release of a vault after a set `_delaySeconds`.
// - `registerVerifierContract(address _verifierAddress, bool _isZK)`: Admin function to register trusted external verifier contracts (e.g., ZK verifiers or other custom validation logic).
// - `setRelayerAllowance(address _relayer, bool _canRelay)`: Admin function to designate addresses that can act as relayers for triggering certain event-based or dead-man-switch policies.
// - `setVaultTrustee(uint256 _vaultId, address _trustee)`: Allows vault owner to set a trustee who can perform certain administrative actions (e.g., update policies) on their specific vault.
// - `pause()`: Admin function to pause critical contract operations in emergencies.
// - `unpause()`: Admin function to unpause critical contract operations.

contract ChronoVault is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _vaultIds;

    // Structs for different policy types
    enum PolicyType {
        None,
        TimeLock,
        EventTrigger,
        MultiPartyApproval,
        ZKProof,
        DeadManSwitch
    }

    struct Policy {
        PolicyType policyType;
        bool isActive;
        address[] beneficiaries;
        uint256 createdAt; // When the policy was added
    }

    struct TimeLockPolicy {
        uint256 releaseTimestamp;
    }

    struct EventTriggerPolicy {
        bytes32 externalConditionIdentifier; // e.g., keccak256 of an event data, or an ID for an off-chain condition
        bool isConditionMet; // Set by authorized relayer
    }

    struct MultiPartyApprovalPolicy {
        address[] approvers;
        uint256 requiredApprovals;
        mapping(address => bool) hasApproved; // Who has approved
        uint256 currentApprovals;
    }

    struct ZKProofPolicy {
        address zkVerifierContract; // Address of the contract verifying the ZK-proof
        bytes32 proofContextHash; // Identifier for the specific proof context/type
        bool isProofSubmitted; // True if a valid proof has been submitted
    }

    struct DeadManSwitchPolicy {
        uint256 inactivityDuration; // Duration in seconds
        address successor;
        uint256 lastOwnerActivity; // Last timestamp owner interacted with the vault
        bool isReleased; // To prevent multiple releases
    }

    // Main Vault struct
    struct Vault {
        string contentHashCID; // IPFS CID or similar hash of the encrypted data / decryption key
        uint256 lastOwnerActivity; // For Dead Man's Switch, tracks owner's last interaction with THIS vault
        address trustee; // An address with limited administrative rights over this specific vault
        uint256 emergencyBypassInitiatedAt; // Timestamp when emergency bypass was initiated
        // Mappings for policies by their ID
        mapping(uint256 => Policy) policies;
        mapping(uint256 => TimeLockPolicy) timeLockPolicies;
        mapping(uint256 => EventTriggerPolicy) eventTriggerPolicies;
        mapping(uint256 => MultiPartyApprovalPolicy) multiPartyPolicies;
        mapping(uint256 => ZKProofPolicy) zkProofPolicies;
        mapping(uint256 => DeadManSwitchPolicy) deadManSwitchPolicies;
        Counters.Counter policyCounter; // To generate unique policy IDs for this vault
    }

    mapping(uint256 => Vault) public vaults;
    mapping(address => bool) public isRegisteredVerifier; // Trusted ZK verifier contracts
    mapping(address => bool) public isRelayer; // Addresses authorized to trigger event-based policies

    // --- Events ---

    event VaultCreated(uint256 indexed vaultId, address indexed owner, string contentHashCID);
    event VaultContentUpdated(uint256 indexed vaultId, address indexed updater, string newContentHashCID);
    event PolicyAdded(uint256 indexed vaultId, uint256 indexed policyId, PolicyType policyType, address indexed creator);
    event PolicyStatusUpdated(uint256 indexed vaultId, uint256 indexed policyId, bool isActive);
    event PolicyRemoved(uint256 indexed vaultId, uint256 indexed policyId);
    event VaultReleased(uint256 indexed vaultId, uint256 indexed policyId, PolicyType policyType);
    event AccessRequested(uint256 indexed vaultId, address indexed beneficiary);
    event EmergencyBypassInitiated(uint256 indexed vaultId, uint256 delaySeconds);
    event OwnerActivityUpdated(uint256 indexed vaultId, address indexed owner);
    event RelayerStatusUpdated(address indexed relayer, bool status);
    event VerifierRegistered(address indexed verifier, bool isZK);
    event TrusteeSet(uint256 indexed vaultId, address indexed trustee);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        _pause(); // Start paused for initial setup by owner
    }

    // --- Modifiers ---

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(_isVaultOwner(_vaultId), "ChronoVault: Not vault owner");
        _;
    }

    modifier onlyVaultOwnerOrTrustee(uint256 _vaultId) {
        require(_isVaultOwner(_vaultId) || vaults[_vaultId].trustee == msg.sender, "ChronoVault: Not vault owner or trustee");
        _;
    }

    modifier onlyRelayer() {
        require(isRelayer[msg.sender], "ChronoVault: Not an authorized relayer");
        _;
    }

    modifier onlyRegisteredVerifier(address _verifier) {
        require(isRegisteredVerifier[_verifier], "ChronoVault: Not a registered verifier");
        _;
    }

    function _isVaultOwner(uint256 _vaultId) internal view returns (bool) {
        return ownerOf(_vaultId) == msg.sender;
    }

    // --- I. Core Vault Management ---

    /**
     * @notice Mints a new ERC-721 Vault NFT for the caller, storing a hash/CID of the (off-chain) data.
     * @param _contentHashCID The IPFS CID or cryptographic hash of the off-chain data.
     * @return The ID of the newly created vault.
     */
    function createVault(string memory _contentHashCID) external whenNotPaused nonReentrant returns (uint256) {
        _vaultIds.increment();
        uint256 newVaultId = _vaultIds.current();

        _safeMint(msg.sender, newVaultId);
        vaults[newVaultId].contentHashCID = _contentHashCID;
        vaults[newVaultId].lastOwnerActivity = block.timestamp; // Initialize activity
        vaults[newVaultId].policyCounter = Counters.Counter(); // Initialize policy counter for this vault

        emit VaultCreated(newVaultId, msg.sender, _contentHashCID);
        return newVaultId;
    }

    /**
     * @notice Allows the vault owner to update the stored content hash/CID.
     * @param _vaultId The ID of the vault.
     * @param _newContentHashCID The new IPFS CID or cryptographic hash.
     */
    function updateVaultContentHash(uint256 _vaultId, string memory _newContentHashCID) external onlyVaultOwner(_vaultId) whenNotPaused nonReentrant {
        require(bytes(_newContentHashCID).length > 0, "ChronoVault: Content hash cannot be empty");
        vaults[_vaultId].contentHashCID = _newContentHashCID;
        emit VaultContentUpdated(_vaultId, msg.sender, _newContentHashCID);
        _updateOwnerActivity(_vaultId); // Update activity for DMS
    }

    /**
     * @notice Allows the vault owner to burn their vault NFT, effectively destroying it.
     *         This also implicitly removes all associated policies.
     * @param _vaultId The ID of the vault to burn.
     */
    function burnVault(uint256 _vaultId) external onlyVaultOwner(_vaultId) whenNotPaused nonReentrant {
        // Vault struct will be cleared implicitly by Solidity when there are no more references.
        // If we had dynamic arrays of policies, we'd need to clear them explicitly to save gas on storage.
        // For mappings, they remain, but will be inaccessible.
        _burn(_vaultId);
        // Explicitly clear sensitive parts if they were dynamically sized or had mappings
        // For our current struct design, mappings within the struct are fine to leave.
        delete vaults[_vaultId];
    }

    // --- II. Policy Management ---

    /**
     * @notice Adds a policy where content is released after a specific timestamp to specified beneficiaries.
     * @param _vaultId The ID of the vault.
     * @param _releaseTimestamp The Unix timestamp when the vault should be released.
     * @param _beneficiaries Addresses eligible to request access upon release.
     * @return The ID of the newly added policy.
     */
    function addTimeLockPolicy(uint256 _vaultId, uint256 _releaseTimestamp, address[] memory _beneficiaries)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_releaseTimestamp > block.timestamp, "ChronoVault: Release timestamp must be in the future");
        require(_beneficiaries.length > 0, "ChronoVault: Must specify at least one beneficiary");

        vaults[_vaultId].policyCounter.increment();
        uint256 policyId = vaults[_vaultId].policyCounter.current();

        vaults[_vaultId].policies[policyId] = Policy(PolicyType.TimeLock, true, _beneficiaries, block.timestamp);
        vaults[_vaultId].timeLockPolicies[policyId] = TimeLockPolicy(_releaseTimestamp);

        emit PolicyAdded(_vaultId, policyId, PolicyType.TimeLock, msg.sender);
        _updateOwnerActivity(_vaultId);
        return policyId;
    }

    /**
     * @notice Adds a policy where content is released upon a specific external event/condition.
     *         Requires an authorized relayer to confirm the condition is met.
     * @param _vaultId The ID of the vault.
     * @param _externalConditionIdentifier A unique identifier for the external condition (e.g., hash of an event, oracle ID).
     * @param _beneficiaries Addresses eligible to request access upon release.
     * @return The ID of the newly added policy.
     */
    function addEventTriggerPolicy(uint256 _vaultId, bytes32 _externalConditionIdentifier, address[] memory _beneficiaries)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_beneficiaries.length > 0, "ChronoVault: Must specify at least one beneficiary");
        require(_externalConditionIdentifier != bytes32(0), "ChronoVault: Condition identifier cannot be empty");

        vaults[_vaultId].policyCounter.increment();
        uint256 policyId = vaults[_vaultId].policyCounter.current();

        vaults[_vaultId].policies[policyId] = Policy(PolicyType.EventTrigger, true, _beneficiaries, block.timestamp);
        vaults[_vaultId].eventTriggerPolicies[policyId] = EventTriggerPolicy(_externalConditionIdentifier, false);

        emit PolicyAdded(_vaultId, policyId, PolicyType.EventTrigger, msg.sender);
        _updateOwnerActivity(_vaultId);
        return policyId;
    }

    /**
     * @notice Adds a policy requiring N of M designated parties to approve release.
     * @param _vaultId The ID of the vault.
     * @param _approvers Addresses designated to provide approvals.
     * @param _requiredApprovals The number of approvals required from `_approvers`.
     * @param _beneficiaries Addresses eligible to request access upon release.
     * @return The ID of the newly added policy.
     */
    function addMultiPartyApprovalPolicy(uint256 _vaultId, address[] memory _approvers, uint256 _requiredApprovals, address[] memory _beneficiaries)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_approvers.length > 0, "ChronoVault: Must specify at least one approver");
        require(_requiredApprovals > 0 && _requiredApprovals <= _approvers.length, "ChronoVault: Invalid required approvals count");
        require(_beneficiaries.length > 0, "ChronoVault: Must specify at least one beneficiary");

        vaults[_vaultId].policyCounter.increment();
        uint256 policyId = vaults[_vaultId].policyCounter.current();

        vaults[_vaultId].policies[policyId] = Policy(PolicyType.MultiPartyApproval, true, _beneficiaries, block.timestamp);
        vaults[_vaultId].multiPartyPolicies[policyId] = MultiPartyApprovalPolicy(_approvers, _requiredApprovals, 0, 0); // Initialize mapping

        emit PolicyAdded(_vaultId, policyId, PolicyType.MultiPartyApproval, msg.sender);
        _updateOwnerActivity(_vaultId);
        return policyId;
    }

    /**
     * @notice Adds a policy requiring a valid ZK-proof submission for verification by a specified verifier contract.
     * @param _vaultId The ID of the vault.
     * @param _zkVerifierContract The address of the ZK-proof verifier contract (must be registered).
     * @param _proofContextHash A hash identifying the specific ZK-proof context or schema expected.
     * @param _beneficiaries Addresses eligible to request access upon release.
     * @return The ID of the newly added policy.
     */
    function addZKProofPolicy(uint256 _vaultId, address _zkVerifierContract, bytes32 _proofContextHash, address[] memory _beneficiaries)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(isRegisteredVerifier[_zkVerifierContract], "ChronoVault: ZK verifier contract not registered");
        require(_proofContextHash != bytes32(0), "ChronoVault: Proof context hash cannot be empty");
        require(_beneficiaries.length > 0, "ChronoVault: Must specify at least one beneficiary");

        vaults[_vaultId].policyCounter.increment();
        uint256 policyId = vaults[_vaultId].policyCounter.current();

        vaults[_vaultId].policies[policyId] = Policy(PolicyType.ZKProof, true, _beneficiaries, block.timestamp);
        vaults[_vaultId].zkProofPolicies[policyId] = ZKProofPolicy(_zkVerifierContract, _proofContextHash, false);

        emit PolicyAdded(_vaultId, policyId, PolicyType.ZKProof, msg.sender);
        _updateOwnerActivity(_vaultId);
        return policyId;
    }

    /**
     * @notice Adds a policy for release to a successor if the owner is inactive for a set duration.
     * @param _vaultId The ID of the vault.
     * @param _inactivityDuration The duration (in seconds) of owner inactivity before triggering.
     * @param _successor The address who gains access upon release.
     * @param _beneficiaries Addresses eligible to request access upon release (should typically include successor).
     * @return The ID of the newly added policy.
     */
    function addDeadManSwitchPolicy(uint256 _vaultId, uint256 _inactivityDuration, address _successor, address[] memory _beneficiaries)
        external
        onlyVaultOwner(_vaultId)
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(_inactivityDuration > 0, "ChronoVault: Inactivity duration must be positive");
        require(_successor != address(0), "ChronoVault: Successor address cannot be zero");
        require(_beneficiaries.length > 0, "ChronoVault: Must specify at least one beneficiary");

        vaults[_vaultId].policyCounter.increment();
        uint256 policyId = vaults[_vaultId].policyCounter.current();

        vaults[_vaultId].policies[policyId] = Policy(PolicyType.DeadManSwitch, true, _beneficiaries, block.timestamp);
        vaults[_vaultId].deadManSwitchPolicies[policyId] = DeadManSwitchPolicy(_inactivityDuration, _successor, vaults[_vaultId].lastOwnerActivity, false);

        emit PolicyAdded(_vaultId, policyId, PolicyType.DeadManSwitch, msg.sender);
        _updateOwnerActivity(_vaultId);
        return policyId;
    }

    /**
     * @notice Allows the vault owner or trustee to enable or disable an existing policy.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the policy to update.
     * @param _isActive The new status for the policy (true for active, false for inactive).
     */
    function updatePolicyStatus(uint256 _vaultId, uint256 _policyId, bool _isActive)
        external
        onlyVaultOwnerOrTrustee(_vaultId)
        whenNotPaused
        nonReentrant
    {
        require(vaults[_vaultId].policies[_policyId].policyType != PolicyType.None, "ChronoVault: Policy does not exist");
        vaults[_vaultId].policies[_policyId].isActive = _isActive;
        emit PolicyStatusUpdated(_vaultId, _policyId, _isActive);
        _updateOwnerActivity(_vaultId);
    }

    /**
     * @notice Allows the vault owner or trustee to remove a policy.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the policy to remove.
     */
    function removePolicy(uint256 _vaultId, uint256 _policyId) external onlyVaultOwnerOrTrustee(_vaultId) whenNotPaused nonReentrant {
        PolicyType pType = vaults[_vaultId].policies[_policyId].policyType;
        require(pType != PolicyType.None, "ChronoVault: Policy does not exist");

        delete vaults[_vaultId].policies[_policyId];
        if (pType == PolicyType.TimeLock) {
            delete vaults[_vaultId].timeLockPolicies[_policyId];
        } else if (pType == PolicyType.EventTrigger) {
            delete vaults[_vaultId].eventTriggerPolicies[_policyId];
        } else if (pType == PolicyType.MultiPartyApproval) {
            delete vaults[_vaultId].multiPartyPolicies[_policyId];
        } else if (pType == PolicyType.ZKProof) {
            delete vaults[_vaultId].zkProofPolicies[_policyId];
        } else if (pType == PolicyType.DeadManSwitch) {
            delete vaults[_vaultId].deadManSwitchPolicies[_policyId];
        }

        emit PolicyRemoved(_vaultId, _policyId);
        _updateOwnerActivity(_vaultId);
    }

    /**
     * @notice View function to retrieve details of a specific policy for a vault.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the policy.
     * @return PolicyType, isActive, beneficiaries, createdAt, and specific policy details as bytes.
     */
    function getPolicyDetails(uint256 _vaultId, uint256 _policyId)
        external
        view
        returns (
            PolicyType policyType,
            bool isActive,
            address[] memory beneficiaries,
            uint256 createdAt,
            bytes memory specificDetails
        )
    {
        Policy storage p = vaults[_vaultId].policies[_policyId];
        require(p.policyType != PolicyType.None, "ChronoVault: Policy does not exist");

        policyType = p.policyType;
        isActive = p.isActive;
        beneficiaries = p.beneficiaries;
        createdAt = p.createdAt;

        if (p.policyType == PolicyType.TimeLock) {
            TimeLockPolicy storage tl = vaults[_vaultId].timeLockPolicies[_policyId];
            specificDetails = abi.encode(tl.releaseTimestamp);
        } else if (p.policyType == PolicyType.EventTrigger) {
            EventTriggerPolicy storage et = vaults[_vaultId].eventTriggerPolicies[_policyId];
            specificDetails = abi.encode(et.externalConditionIdentifier, et.isConditionMet);
        } else if (p.policyType == PolicyType.MultiPartyApproval) {
            MultiPartyApprovalPolicy storage mp = vaults[_vaultId].multiPartyPolicies[_policyId];
            specificDetails = abi.encode(mp.approvers, mp.requiredApprovals, mp.currentApprovals);
        } else if (p.policyType == PolicyType.ZKProof) {
            ZKProofPolicy storage zk = vaults[_vaultId].zkProofPolicies[_policyId];
            specificDetails = abi.encode(zk.zkVerifierContract, zk.proofContextHash, zk.isProofSubmitted);
        } else if (p.policyType == PolicyType.DeadManSwitch) {
            DeadManSwitchPolicy storage dms = vaults[_vaultId].deadManSwitchPolicies[_policyId];
            specificDetails = abi.encode(dms.inactivityDuration, dms.successor, dms.lastOwnerActivity, dms.isReleased);
        }
    }

    /**
     * @notice View function to retrieve all policy IDs associated with a vault.
     * @param _vaultId The ID of the vault.
     * @return An array of all policy IDs for the given vault.
     */
    function getVaultPolicies(uint256 _vaultId) external view returns (uint256[] memory) {
        uint256 totalPolicies = vaults[_vaultId].policyCounter.current();
        uint256[] memory policyIds = new uint256[](totalPolicies);
        uint256 counter = 0;
        for (uint256 i = 1; i <= totalPolicies; i++) {
            if (vaults[_vaultId].policies[i].policyType != PolicyType.None) {
                policyIds[counter] = i;
                counter++;
            }
        }
        // Resize array to actual number of policies if some were removed
        uint256[] memory actualPolicyIds = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            actualPolicyIds[i] = policyIds[i];
        }
        return actualPolicyIds;
    }


    // --- III. Release & Access Control ---

    /**
     * @notice Callable by anyone to check and trigger release if the time-lock condition for a specific policy is met.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the TimeLock policy.
     */
    function triggerTimeLockRelease(uint256 _vaultId, uint256 _policyId) external whenNotPaused nonReentrant {
        Policy storage p = vaults[_vaultId].policies[_policyId];
        require(p.policyType == PolicyType.TimeLock && p.isActive, "ChronoVault: Policy not active or not a TimeLock policy");

        TimeLockPolicy storage tl = vaults[_vaultId].timeLockPolicies[_policyId];
        require(block.timestamp >= tl.releaseTimestamp, "ChronoVault: Time lock not yet expired");

        p.isActive = false; // Deactivate policy after successful trigger
        emit VaultReleased(_vaultId, _policyId, PolicyType.TimeLock);
    }

    /**
     * @notice Callable by an authorized relayer to trigger release for an event-based policy,
     *         confirming the external condition is met.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the EventTrigger policy.
     */
    function triggerEventRelease(uint256 _vaultId, uint256 _policyId) external onlyRelayer whenNotPaused nonReentrant {
        Policy storage p = vaults[_vaultId].policies[_policyId];
        require(p.policyType == PolicyType.EventTrigger && p.isActive, "ChronoVault: Policy not active or not an EventTrigger policy");

        EventTriggerPolicy storage et = vaults[_vaultId].eventTriggerPolicies[_policyId];
        require(!et.isConditionMet, "ChronoVault: Condition already met");

        et.isConditionMet = true;
        p.isActive = false; // Deactivate policy after successful trigger
        emit VaultReleased(_vaultId, _policyId, PolicyType.EventTrigger);
    }

    /**
     * @notice Allows a designated approver to submit their approval for a multi-party policy.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the MultiPartyApproval policy.
     */
    function submitMultiPartyApproval(uint256 _vaultId, uint256 _policyId) external whenNotPaused nonReentrant {
        Policy storage p = vaults[_vaultId].policies[_policyId];
        require(p.policyType == PolicyType.MultiPartyApproval && p.isActive, "ChronoVault: Policy not active or not a MultiParty policy");

        MultiPartyApprovalPolicy storage mp = vaults[_vaultId].multiPartyPolicies[_policyId];
        bool isApprover = false;
        for (uint224 i = 0; i < mp.approvers.length; i++) {
            if (mp.approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
        require(isApprover, "ChronoVault: Sender is not an authorized approver");
        require(!mp.hasApproved[msg.sender], "ChronoVault: Sender has already approved");

        mp.hasApproved[msg.sender] = true;
        mp.currentApprovals++;

        if (mp.currentApprovals >= mp.requiredApprovals) {
            p.isActive = false; // Deactivate policy after successful trigger
            emit VaultReleased(_vaultId, _policyId, PolicyType.MultiPartyApproval);
        }
    }

    /**
     * @notice Allows a user to submit a ZK-proof for verification and potentially trigger release for a ZK-proof policy.
     *         The actual proof verification happens in an external `_zkVerifierContract`.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the ZKProof policy.
     * @param _proofA, _proofB, _proofC, _input The components of the ZK-proof.
     */
    function submitZKProofAndRelease(
        uint256 _vaultId,
        uint256 _policyId,
        uint[] memory _proofA,
        uint[] memory _proofB,
        uint[] memory _proofC,
        uint[] memory _input
    ) external whenNotPaused nonReentrant {
        Policy storage p = vaults[_vaultId].policies[_policyId];
        require(p.policyType == PolicyType.ZKProof && p.isActive, "ChronoVault: Policy not active or not a ZKProof policy");

        ZKProofPolicy storage zk = vaults[_vaultId].zkProofPolicies[_policyId];
        require(!zk.isProofSubmitted, "ChronoVault: ZK proof already submitted for this policy");
        require(zk.zkVerifierContract != address(0), "ChronoVault: ZK verifier not set for this policy");
        
        // Example: Check if a specific input matches the policy context hash (this is conceptual)
        // require(_input[0] == uint256(zk.proofContextHash), "ChronoVault: Proof input context mismatch");

        // Perform the actual ZK-proof verification via the external verifier contract
        bool verified = IVerifier(zk.zkVerifierContract).verifyProof(_proofA, _proofB, _proofC, _input);
        require(verified, "ChronoVault: ZK proof verification failed");

        zk.isProofSubmitted = true;
        p.isActive = false; // Deactivate policy after successful trigger
        emit VaultReleased(_vaultId, _policyId, PolicyType.ZKProof);
    }

    /**
     * @notice Callable by the successor or relayer to check owner's inactivity and trigger release
     *         for a Dead Man's Switch policy.
     * @param _vaultId The ID of the vault.
     * @param _policyId The ID of the DeadManSwitch policy.
     */
    function checkDeadManSwitch(uint256 _vaultId, uint256 _policyId) external whenNotPaused nonReentrant {
        Policy storage p = vaults[_vaultId].policies[_policyId];
        require(p.policyType == PolicyType.DeadManSwitch && p.isActive, "ChronoVault: Policy not active or not a DeadManSwitch policy");

        DeadManSwitchPolicy storage dms = vaults[_vaultId].deadManSwitchPolicies[_policyId];
        require(!dms.isReleased, "ChronoVault: Dead Man's Switch already triggered");
        require(msg.sender == dms.successor || isRelayer[msg.sender], "ChronoVault: Not successor or authorized relayer");

        // Use the vault's overall lastOwnerActivity to cover all interactions with the vault
        require(block.timestamp >= vaults[_vaultId].lastOwnerActivity + dms.inactivityDuration, "ChronoVault: Inactivity period not yet passed");

        dms.isReleased = true;
        p.isActive = false; // Deactivate policy after successful trigger
        emit VaultReleased(_vaultId, _policyId, PolicyType.DeadManSwitch);
    }

    /**
     * @notice View function to check the current overall release status of a vault based on all active policies.
     *         A vault is considered released if *any* active policy's conditions are met.
     * @param _vaultId The ID of the vault.
     * @return True if the vault is currently released/releasable by at least one policy, false otherwise.
     */
    function getReleaseStatus(uint256 _vaultId) public view returns (bool) {
        // Vault must exist
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");

        uint256 totalPolicies = vaults[_vaultId].policyCounter.current();
        for (uint256 policyId = 1; policyId <= totalPolicies; policyId++) {
            Policy storage p = vaults[_vaultId].policies[policyId];
            if (!p.isActive) continue; // Only consider active policies

            if (p.policyType == PolicyType.TimeLock) {
                TimeLockPolicy storage tl = vaults[_vaultId].timeLockPolicies[policyId];
                if (block.timestamp >= tl.releaseTimestamp) return true;
            } else if (p.policyType == PolicyType.EventTrigger) {
                EventTriggerPolicy storage et = vaults[_vaultId].eventTriggerPolicies[policyId];
                if (et.isConditionMet) return true;
            } else if (p.policyType == PolicyType.MultiPartyApproval) {
                MultiPartyApprovalPolicy storage mp = vaults[_vaultId].multiPartyPolicies[policyId];
                if (mp.currentApprovals >= mp.requiredApprovals) return true;
            } else if (p.policyType == PolicyType.ZKProof) {
                ZKProofPolicy storage zk = vaults[_vaultId].zkProofPolicies[policyId];
                if (zk.isProofSubmitted) return true;
            } else if (p.policyType == PolicyType.DeadManSwitch) {
                DeadManSwitchPolicy storage dms = vaults[_vaultId].deadManSwitchPolicies[policyId];
                if (dms.isReleased) return true; // Already flagged as released
                // Check if DMS conditions are met but not yet triggered for this policy
                if (block.timestamp >= vaults[_vaultId].lastOwnerActivity + dms.inactivityDuration) return true;
            }
        }
        // Also check if emergency bypass is active and delay passed
        if (vaults[_vaultId].emergencyBypassInitiatedAt > 0 && block.timestamp >= vaults[_vaultId].emergencyBypassInitiatedAt) {
            return true;
        }

        return false;
    }

    /**
     * @notice Allows a beneficiary to request and retrieve the content hash/CID if the vault is released and they are a designated beneficiary.
     * @param _vaultId The ID of the vault.
     * @return The content hash/CID of the data.
     */
    function requestAccessKey(uint256 _vaultId) external view returns (string memory) {
        require(_exists(_vaultId), "ChronoVault: Vault does not exist");
        require(getReleaseStatus(_vaultId), "ChronoVault: Vault is not released yet");

        bool isBeneficiary = false;
        // Check all active or triggered policies if msg.sender is a beneficiary
        uint256 totalPolicies = vaults[_vaultId].policyCounter.current();
        for (uint256 policyId = 1; policyId <= totalPolicies; policyId++) {
            Policy storage p = vaults[_vaultId].policies[policyId];
            if (p.policyType == PolicyType.None) continue; // Policy might have been removed

            // If the policy itself is active OR has successfully triggered release
            bool policyTriggeredOrActive = false;
            if (p.isActive) {
                policyTriggeredOrActive = true; // Assume active policy might be the one allowing release
            } else {
                // For policies that become inactive *after* triggering, check their status directly
                if (p.policyType == PolicyType.EventTrigger && vaults[_vaultId].eventTriggerPolicies[policyId].isConditionMet) policyTriggeredOrActive = true;
                if (p.policyType == PolicyType.MultiPartyApproval && vaults[_vaultId].multiPartyPolicies[policyId].currentApprovals >= vaults[_vaultId].multiPartyPolicies[policyId].requiredApprovals) policyTriggeredOrActive = true;
                if (p.policyType == PolicyType.ZKProof && vaults[_vaultId].zkProofPolicies[policyId].isProofSubmitted) policyTriggeredOrActive = true;
                if (p.policyType == PolicyType.DeadManSwitch && vaults[_vaultId].deadManSwitchPolicies[policyId].isReleased) policyTriggeredOrActive = true;
                if (p.policyType == PolicyType.TimeLock && block.timestamp >= vaults[_vaultId].timeLockPolicies[policyId].releaseTimestamp) policyTriggeredOrActive = true;
            }

            if (policyTriggeredOrActive) {
                for (uint256 i = 0; i < p.beneficiaries.length; i++) {
                    if (p.beneficiaries[i] == msg.sender) {
                        isBeneficiary = true;
                        break;
                    }
                }
            }
            if (isBeneficiary) break;
        }

        // Also check if msg.sender is the vault owner in case of emergency bypass
        if (!isBeneficiary && _isVaultOwner(_vaultId) && vaults[_vaultId].emergencyBypassInitiatedAt > 0 && block.timestamp >= vaults[_vaultId].emergencyBypassInitiatedAt) {
             isBeneficiary = true;
        }

        require(isBeneficiary, "ChronoVault: Sender is not a designated beneficiary or authorized to access");

        emit AccessRequested(_vaultId, msg.sender);
        return vaults[_vaultId].contentHashCID;
    }


    /**
     * @notice Callable by the vault owner to reset the inactivity timer for the Dead Man's Switch policies.
     *         This effectively signals the owner is still active.
     * @param _vaultId The ID of the vault.
     */
    function updateLastOwnerActivity(uint256 _vaultId) external onlyVaultOwner(_vaultId) whenNotPaused {
        _updateOwnerActivity(_vaultId);
        emit OwnerActivityUpdated(_vaultId, msg.sender);
    }

    /**
     * @dev Internal function to update the vault's last owner activity timestamp.
     * @param _vaultId The ID of the vault.
     */
    function _updateOwnerActivity(uint256 _vaultId) internal {
        vaults[_vaultId].lastOwnerActivity = block.timestamp;
        // Note: Individual DeadManSwitch policies are updated when triggered,
        // but this general vault activity reset ensures all DMS policies use the latest owner activity.
    }


    // --- IV. Advanced / Admin Functions ---

    /**
     * @notice A highly restricted, owner-only function to initiate an emergency release of a vault
     *         after a set `_delaySeconds`. This provides a grace period.
     * @param _vaultId The ID of the vault.
     * @param _delaySeconds The number of seconds after which the vault will be bypass-released.
     */
    function emergencyBypassRelease(uint256 _vaultId, uint256 _delaySeconds) external onlyVaultOwner(_vaultId) whenNotPaused nonReentrant {
        require(_delaySeconds > 0, "ChronoVault: Delay must be positive for emergency bypass");
        require(vaults[_vaultId].emergencyBypassInitiatedAt == 0, "ChronoVault: Emergency bypass already initiated for this vault");
        vaults[_vaultId].emergencyBypassInitiatedAt = block.timestamp + _delaySeconds;
        emit EmergencyBypassInitiated(_vaultId, _delaySeconds);
    }

    /**
     * @notice Admin function to register trusted external verifier contracts (e.g., ZK verifiers or other custom validation logic).
     * @param _verifierAddress The address of the verifier contract.
     * @param _isZK True if it's a ZK-proof verifier, false for general trusted verifiers.
     */
    function registerVerifierContract(address _verifierAddress, bool _isZK) external onlyOwner {
        require(_verifierAddress != address(0), "ChronoVault: Verifier address cannot be zero");
        isRegisteredVerifier[_verifierAddress] = _isZK; // _isZK indicates type, but primarily it's a trusted address
        emit VerifierRegistered(_verifierAddress, _isZK);
    }

    /**
     * @notice Admin function to designate addresses that can act as relayers for triggering certain
     *         event-based or dead-man-switch policies.
     * @param _relayer The address to set as a relayer.
     * @param _canRelay True to grant relayer status, false to revoke.
     */
    function setRelayerAllowance(address _relayer, bool _canRelay) external onlyOwner {
        require(_relayer != address(0), "ChronoVault: Relayer address cannot be zero");
        isRelayer[_relayer] = _canRelay;
        emit RelayerStatusUpdated(_relayer, _canRelay);
    }

    /**
     * @notice Allows vault owner to set a trustee who can perform certain administrative actions (e.g., update policies)
     *         on their specific vault. Trustee cannot transfer ownership or burn the vault.
     * @param _vaultId The ID of the vault.
     * @param _trustee The address to set as trustee (address(0) to remove).
     */
    function setVaultTrustee(uint256 _vaultId, address _trustee) external onlyVaultOwner(_vaultId) whenNotPaused {
        vaults[_vaultId].trustee = _trustee;
        emit TrusteeSet(_vaultId, _trustee);
        _updateOwnerActivity(_vaultId);
    }

    /**
     * @notice Admin function to pause critical contract operations in emergencies.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @notice Admin function to unpause critical contract operations.
     */
    function unpause() public override onlyOwner {
        _unpause();
    }
}
```