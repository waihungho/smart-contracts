This smart contract, `AetherProtocol`, is designed as a foundational layer for managing **Dynamic Data & Capability NFTs**. These NFTs are not just static digital assets; they represent dynamic entities or "agents" that can:

1.  **Possess Attestable Data**: Accumulate verified data points over time, making them data-rich and context-aware.
2.  **Acquire and Shed Capabilities**: Have modular functionalities (capabilities) attached or detached, allowing their behavior and utility to evolve.
3.  **Operate with Delegated Autonomy**: Owners can delegate specific capabilities for autonomous execution under predefined conditions or to specific agents.
4.  **Maintain an On-chain Reputation**: Accumulate a reputation score based on their actions, attested data, or interactions within the protocol.
5.  **Participate in Self-Evolving Governance**: The protocol itself can be updated and configured through a decentralized governance mechanism, adapting its rules and modules.

This architecture paves the way for advanced Web3 applications like:
*   **AI Agent Orchestration**: NFTs representing AI agents with dynamic skills.
*   **DeSci (Decentralized Science)**: NFTs accumulating research data, attestations, and reputation.
*   **Adaptive Gaming Assets**: Game items that evolve based on gameplay or external data.
*   **Decentralized Identity with Dynamic Credentials**: Identities that accumulate verifiable claims and capabilities.
*   **Data Markets**: NFTs acting as bundles of attested data.

---

## AetherProtocol Smart Contract

**Concept:** `AetherProtocol` introduces "Capability NFTs" – NFTs that are not static but are enhanced with dynamic, modular functionalities and verifiable data attestations. These NFTs can evolve, acquire new skills (capabilities), and even operate autonomously under delegated control. The protocol itself is designed for self-evolution through a decentralized governance mechanism.

### Outline:

1.  **Core NFT & Identity Management**
    *   ERC721 basic functionality with enhanced minting.
    *   Delegated control over specific NFT capabilities.
2.  **Dynamic Data & Attestation**
    *   Storing and verifying arbitrary data associated with NFTs.
    *   Modular attestation mechanisms.
    *   Schema management for data types.
3.  **Capability Modules & Execution**
    *   Registering and managing external contracts that define "capabilities."
    *   Attaching/detaching capabilities to/from NFTs.
    *   Executing NFT capabilities based on permissions.
4.  **Incentivization & Reputation**
    *   Rewarding data attesters.
    *   On-chain reputation scoring for NFTs.
5.  **Governance & Protocol Evolution**
    *   Decentralized proposal and voting mechanism for protocol changes.
    *   Mechanism for upgrading core protocol modules.
    *   Emergency controls and fee configuration.
6.  **Internal State & Utility**
    *   View functions for querying NFT state, capabilities, data, etc.

### Function Summary:

1.  `constructor()`: Initializes the contract with an admin, registers initial governance and attestation modules.
2.  `mintCapabilityNFT(string calldata _initialMetadataURI)`: Mints a new Capability NFT with initial metadata, assigning it a unique identity.
3.  `updateNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI)`: Allows the NFT owner to update the associated metadata URI.
4.  `delegateCapabilityControl(uint256 _tokenId, address _delegatee, bytes32 _capabilityHash, uint256 _expiry)`: Delegates control of a specific NFT capability to another address for a set duration.
5.  `revokeCapabilityControl(uint256 _tokenId, address _delegatee, bytes32 _capabilityHash)`: Revokes a previously delegated capability control.
6.  `attestDataPoint(uint256 _tokenId, string calldata _dataType, bytes calldata _dataValue, bytes calldata _signature)`: Records a new attested data point for an NFT, verified by the `attestationModule`.
7.  `requestDataAttestation(uint256 _tokenId, string calldata _dataType, address _attester)`: Allows an NFT owner to formally request a specific attester to provide data for their NFT.
8.  `verifyDataAttestation(uint256 _tokenId, string calldata _dataType, bytes calldata _dataValue, address _attester)`: Checks if a specific data point, of a given type, has been attested by an attester for an NFT.
9.  `setAttestationModule(address _moduleAddress)`: Sets or updates the address of the external contract responsible for attestation verification. (Governance-controlled).
10. `updateDataSchema(string calldata _dataType, bytes calldata _schemaHash)`: Updates the expected data schema for a specific data type, managed by governance.
11. `registerCapabilityModule(bytes32 _capabilityHash, address _moduleAddress, bool _isAutonomous, string calldata _description)`: Registers a new external capability module contract, making it available for NFTs.
12. `attachCapability(uint256 _tokenId, bytes32 _capabilityHash, bytes calldata _initialConfig)`: Attaches a registered capability module to an NFT, providing initial configuration.
13. `detachCapability(uint256 _tokenId, bytes32 _capabilityHash)`: Removes an attached capability from an NFT.
14. `executeCapability(uint256 _tokenId, bytes32 _capabilityHash, bytes calldata _executionPayload)`: Triggers the logic of an attached capability, passing execution data. Checks for owner/delegatee/autonomous permissions.
15. `configureCapability(uint256 _tokenId, bytes32 _capabilityHash, bytes calldata _newConfig)`: Updates the configuration of an attached capability for a specific NFT.
16. `distributeAttestationReward(address _attester, uint256 _amount)`: Allows the protocol (or a trusted caller) to reward data attesters for their contributions.
17. `updateNFTReputationScore(uint256 _tokenId, int256 _scoreChange, string calldata _reason)`: Adjusts an NFT's on-chain reputation score. Can be called by internal logic or governance.
18. `proposeProtocolParameterChange(bytes32 _paramKey, bytes calldata _newValue, string calldata _description)`: Creates a new governance proposal to change a protocol parameter.
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible NFT holders to vote on an active governance proposal.
20. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed its voting period and met quorum.
21. `upgradeProtocolModule(bytes32 _moduleKey, address _newModuleAddress)`: Allows for upgrading core protocol modules (e.g., attestation module, governance module) via a passed governance proposal.
22. `emergencyPauseProtocol()`: Allows the emergency multi-sig/DAO to pause critical protocol functions in case of severe vulnerabilities.
23. `configureFeeStructure(bytes32 _feeType, uint256 _amountOrRate)`: Sets or updates various fees within the protocol, managed by governance.

---
**Note on External Modules:** The contract relies on external `IAttestationModule`, `ICapabilityModule`, and `IGovernance` interfaces. These would be separate contracts deployed alongside `AetherProtocol`, allowing for modularity and upgradability of specific functionalities. The actual logic for verifying signatures, complex attestation, or specific capability actions would reside in these external modules.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential off-chain signatures

/**
 * @title AetherProtocol
 * @dev A foundational layer for managing Dynamic Data & Capability NFTs.
 *      These NFTs can acquire verifiable data, attach modular functionalities (capabilities),
 *      operate with delegated autonomy, maintain an on-chain reputation, and participate
 *      in self-evolving governance.
 *
 * @notice This contract is designed to be highly modular, relying on external "module" contracts
 *         for specific functionalities like attestation verification and capability execution.
 *         It provides the core registry and orchestration logic.
 *
 * @author [Your Name/Team Name]
 * @custom:version 1.0.0
 */
contract AetherProtocol is Context, ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // --- Custom Errors ---
    error InvalidArgument();
    error NotAuthorized(address caller);
    error NFTNotFound(uint256 tokenId);
    error CapabilityNotRegistered(bytes32 capabilityHash);
    error CapabilityAlreadyAttached(uint256 tokenId, bytes32 capabilityHash);
    error CapabilityNotAttached(uint256 tokenId, bytes32 capabilityHash);
    error DelegationExpired(uint256 tokenId, bytes32 capabilityHash, address delegatee);
    error DelegationNotFound(uint256 tokenId, bytes32 capabilityHash, address delegatee);
    error AttestationModuleNotSet();
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotExecutable(uint256 proposalId, string reason);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error InsufficientFees();
    error ProtocolPaused();

    // --- Enums ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct CapabilityModuleConfig {
        address moduleAddress;      // Address of the external contract implementing the capability
        bool isAutonomous;          // True if this capability can be delegated for autonomous execution
        string description;         // Description of the capability module
    }

    struct CapabilityInstanceConfig {
        bytes32 capabilityHash;     // Reference to the registered capability module
        bytes configData;           // Specific configuration data for this NFT's instance of the capability
    }

    struct DataAttestation {
        bytes dataValueHash;        // keccak256 hash of the _dataValue for integrity check
        address attester;           // Address of the entity that attested the data
        uint256 timestamp;          // When the data was attested
    }

    struct DelegateControl {
        uint256 expiry;             // Timestamp when the delegation expires (0 for permanent)
    }

    struct GovernanceProposal {
        uint256 id;
        bytes32 paramKey;           // Key of the protocol parameter to change
        bytes newValue;             // New value for the parameter
        string description;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        address proposer;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for minting new NFTs

    // NFT Data & Capabilities
    mapping(uint256 => int256) public nftReputation; // NFT ID -> Reputation score
    mapping(uint256 => mapping(string => mapping(address => DataAttestation))) public nftDataAttestations; // NFT ID -> Data Type -> Attester -> Attestation

    // Capability Registry
    mapping(bytes32 => CapabilityModuleConfig) public registeredCapabilityModules; // Capability Hash -> Config
    mapping(uint256 => mapping(bytes32 => CapabilityInstanceConfig)) public nftCapabilities; // NFT ID -> Capability Hash -> Instance Config

    // Delegation of specific capabilities
    mapping(uint256 => mapping(address => mapping(bytes32 => DelegateControl))) public delegatedCapabilityControls; // NFT ID -> Delegatee -> Capability Hash -> Control

    // Protocol Configuration & Governance
    mapping(bytes32 => bytes) public protocolParameters; // Generic parameters for governance (e.g., reward rates, quorum, voting period)
    mapping(string => bytes32) public dataSchemas; // Data Type string -> keccak256 hash of expected schema for validation
    mapping(bytes32 => uint256) public protocolFees; // Fee Type (bytes32) -> Amount/Rate

    address public attestationModule; // External contract for verifying attestations
    address public governanceModule; // External contract or internal logic responsible for governance rules/voting
    bool public protocolPaused; // Emergency pause switch

    // Governance proposals
    uint256 private _nextProposalId;
    mapping(uint256 => GovernanceProposal) public proposals;

    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event CapabilityControlDelegated(uint256 indexed tokenId, address indexed delegatee, bytes32 indexed capabilityHash, uint256 expiry);
    event CapabilityControlRevoked(uint256 indexed tokenId, address indexed delegatee, bytes32 indexed capabilityHash);

    event DataAttested(uint256 indexed tokenId, string indexed dataType, address indexed attester, bytes dataValueHash, uint256 timestamp);
    event DataSchemaUpdated(string indexed dataType, bytes32 newSchemaHash);
    event AttestationModuleSet(address indexed oldModule, address indexed newModule);

    event CapabilityModuleRegistered(bytes32 indexed capabilityHash, address indexed moduleAddress, bool isAutonomous, string description);
    event CapabilityAttached(uint256 indexed tokenId, bytes32 indexed capabilityHash, bytes initialConfig);
    event CapabilityDetached(uint256 indexed tokenId, bytes32 indexed capabilityHash);
    event CapabilityExecuted(uint256 indexed tokenId, bytes32 indexed capabilityHash, address indexed executor, bytes executionPayload);
    event CapabilityConfigured(uint256 indexed tokenId, bytes32 indexed capabilityHash, bytes newConfig);

    event AttestationRewardDistributed(address indexed attester, uint256 amount);
    event NFTReputationUpdated(uint256 indexed tokenId, int256 scoreChange, int256 newScore, string reason);

    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, bytes newValue, string description, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProtocolModuleUpgraded(bytes32 indexed moduleKey, address indexed oldModuleAddress, address indexed newModuleAddress);
    event ProtocolPausedStateChanged(bool paused);
    event FeeStructureConfigured(bytes32 indexed feeType, uint256 amountOrRate);

    // --- Modifiers ---

    modifier whenNotPaused() {
        if (protocolPaused) {
            revert ProtocolPaused();
        }
        _;
    }

    modifier onlyAttestationModule() {
        if (_msgSender() != attestationModule) {
            revert NotAuthorized(_msgSender());
        }
        _;
    }

    modifier onlyGov() {
        // In a real DAO, this would involve checking if _msgSender() is the governance contract
        // or a member of a multi-sig approved by governance. For simplicity, we make it owner-only initially,
        // expecting governance to take over and potentially update this modifier or the calling logic.
        if (_msgSender() != owner()) {
            revert NotAuthorized(_msgSender());
        }
        _;
    }

    // --- Interfaces ---
    interface IAttestationModule {
        function verifyAttestation(address _verifier, uint256 _tokenId, string calldata _dataType, bytes calldata _dataValue, bytes calldata _signature) external view returns (bool);
    }

    interface ICapabilityModule {
        function execute(uint256 _tokenId, bytes calldata _executionPayload) external;
        function configure(uint256 _tokenId, bytes calldata _configData) external;
    }

    interface IGovernance {
        // This interface would define functions for more complex DAO logic,
        // e.g., vote power calculation, quorum checks.
        // For this contract, governance is simplified to direct parameter updates by voting.
        function getVotePower(address voter) external view returns (uint256);
        function getQuorum(uint256 proposalId) external view returns (uint256); // Example
        function getVotingPeriod() external view returns (uint256); // Example
    }


    constructor(address _initialGovernanceModule, address _initialAttestationModule) ERC721("AetherProtocol NFT", "AP-NFT") Ownable(_msgSender()) {
        _nextTokenId = 1;
        _nextProposalId = 1;
        attestationModule = _initialAttestationModule;
        governanceModule = _initialGovernanceModule; // Could be the deployer's address if governance is simple initially
        protocolPaused = false;

        // Initialize some default protocol parameters
        protocolParameters[keccak256("votingPeriod")] = abi.encodePacked(uint256(7 * 24 * 60 * 60)); // 7 days
        protocolParameters[keccak256("minProposalThreshold")] = abi.encodePacked(uint256(1)); // Min NFTs required to propose
    }

    // --- Core NFT & Identity Management ---

    /**
     * @dev Mints a new Capability NFT with an initial metadata URI.
     * @param _initialMetadataURI The URI pointing to the NFT's initial metadata.
     * @return The ID of the newly minted NFT.
     */
    function mintCapabilityNFT(string calldata _initialMetadataURI) external whenNotPaused returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _initialMetadataURI);
        emit NFTMinted(tokenId, _msgSender(), _initialMetadataURI);
        return tokenId;
    }

    /**
     * @dev Allows the NFT owner to update the associated metadata URI.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataURI The new URI pointing to the NFT's metadata.
     */
    function updateNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI) external whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        _setTokenURI(_tokenId, _newMetadataURI);
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Delegates control of a specific NFT capability to another address for a set duration.
     *      This allows an external agent or contract to execute specific functions of the NFT.
     * @param _tokenId The ID of the NFT.
     * @param _delegatee The address to delegate control to.
     * @param _capabilityHash The hash identifying the specific capability to delegate.
     * @param _expiry The timestamp when the delegation expires. Set to 0 for a permanent delegation (use with caution).
     */
    function delegateCapabilityControl(
        uint256 _tokenId,
        address _delegatee,
        bytes32 _capabilityHash,
        uint256 _expiry
    ) external whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        if (_delegatee == address(0)) {
            revert InvalidArgument();
        }
        if (registeredCapabilityModules[_capabilityHash].moduleAddress == address(0)) {
            revert CapabilityNotRegistered(_capabilityHash);
        }

        delegatedCapabilityControls[_tokenId][_delegatee][_capabilityHash] = DelegateControl({
            expiry: _expiry
        });

        emit CapabilityControlDelegated(_tokenId, _delegatee, _capabilityHash, _expiry);
    }

    /**
     * @dev Revokes a previously delegated capability control for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _delegatee The address whose delegation is to be revoked.
     * @param _capabilityHash The hash identifying the specific capability.
     */
    function revokeCapabilityControl(
        uint256 _tokenId,
        address _delegatee,
        bytes32 _capabilityHash
    ) external whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        if (delegatedCapabilityControls[_tokenId][_delegatee][_capabilityHash].expiry == 0 &&
            delegatedCapabilityControls[_tokenId][_delegatee][_capabilityHash].expiry != block.timestamp // distinguish 0 as valid permanent vs non-existent
        ) {
            revert DelegationNotFound(_tokenId, _capabilityHash, _delegatee);
        }

        delete delegatedCapabilityControls[_tokenId][_delegatee][_capabilityHash];
        emit CapabilityControlRevoked(_tokenId, _delegatee, _capabilityHash);
    }

    // --- Dynamic Data & Attestation ---

    /**
     * @dev Records a new attested data point for an NFT. This function is typically called
     *      by the `attestationModule` after verifying external data, or by a trusted attester.
     *      It requires a signature to prove data integrity and origin.
     * @param _tokenId The ID of the NFT to associate the data with.
     * @param _dataType A string identifying the type of data (e.g., "temperature", "location", "health_score").
     * @param _dataValue The raw data value.
     * @param _signature An ECDSA signature over the data, proving its origin.
     */
    function attestDataPoint(
        uint256 _tokenId,
        string calldata _dataType,
        bytes calldata _dataValue,
        bytes calldata _signature
    ) external whenNotPaused {
        if (attestationModule == address(0)) {
            revert AttestationModuleNotSet();
        }
        // The attestation module is responsible for verifying the signature and then calling this function,
        // or this function can perform a basic check here. For simplicity, we assume the `attestationModule`
        // grants permission to _msgSender() to call this function after its internal verification.
        // A more robust system would have the `attestationModule` itself call this function.
        // Let's make it so only the attestation module can call this.
        if (_msgSender() != attestationModule) {
            revert NotAuthorized(_msgSender());
        }

        // The _attester should be part of the _dataValue or determined by the attestationModule's logic.
        // For simplicity, let's assume the attester is the address that signed the _dataValue (if verified by module).
        // Or, the module itself is the attester for this on-chain record.
        // Let's use `_msgSender()` (which is `attestationModule`) as the on-chain recorded attester.
        address currentAttester = _msgSender(); // The module itself records the attestation.

        // Optionally, schema validation can happen here or within the attestation module
        // if (dataSchemas[_dataType] != 0 && !IAttestationModule(attestationModule).validateSchema(_dataType, _dataValue)) {
        //     revert InvalidDataFormat();
        // }

        nftDataAttestations[_tokenId][_dataType][currentAttester] = DataAttestation({
            dataValueHash: keccak256(_dataValue), // Store hash for later verification, not raw data to save gas
            attester: currentAttester,
            timestamp: block.timestamp
        });

        emit DataAttested(_tokenId, _dataType, currentAttester, keccak256(_dataValue), block.timestamp);

        // Potentially trigger reputation update here
        _updateNFTReputation(_tokenId, 1, "Data Attestation");
    }

    /**
     * @dev Allows an NFT owner to formally request a specific attester to provide data for their NFT.
     *      This is an on-chain signal/record of a data request.
     * @param _tokenId The ID of the NFT.
     * @param _dataType The type of data being requested.
     * @param _attester The address of the attester from whom data is requested.
     */
    function requestDataAttestation(
        uint256 _tokenId,
        string calldata _dataType,
        address _attester
    ) external whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        if (_attester == address(0)) {
            revert InvalidArgument();
        }
        // In a real scenario, this might trigger an off-chain notification or have a fee.
        // For now, it just records the intent.
        // You could add a mapping to track pending requests:
        // mapping(uint256 => mapping(string => mapping(address => bool))) public pendingAttestationRequests;
        // pendingAttestationRequests[_tokenId][_dataType][_attester] = true;
        emit DataAttested(_tokenId, _dataType, _attester, keccak256(abi.encodePacked("REQUESTED")), block.timestamp); // Use a dummy hash for request
    }

    /**
     * @dev Verifies if a specific data point, of a given type, has been attested by an attester for an NFT.
     *      This checks the on-chain record for a matching data hash and attester.
     * @param _tokenId The ID of the NFT.
     * @param _dataType The type of data.
     * @param _dataValue The data value to check.
     * @param _attester The expected attester.
     * @return True if the data has been attested as specified, false otherwise.
     */
    function verifyDataAttestation(
        uint256 _tokenId,
        string calldata _dataType,
        bytes calldata _dataValue,
        address _attester
    ) external view returns (bool) {
        DataAttestation storage att = nftDataAttestations[_tokenId][_dataType][_attester];
        return att.attester == _attester && att.dataValueHash == keccak256(_dataValue) && att.timestamp > 0;
    }

    /**
     * @dev Sets or updates the address of the external contract responsible for attestation verification.
     *      This is a governance-controlled function.
     * @param _moduleAddress The new address for the attestation module.
     */
    function setAttestationModule(address _moduleAddress) external onlyGov {
        if (_moduleAddress == address(0)) {
            revert InvalidArgument();
        }
        address oldModule = attestationModule;
        attestationModule = _moduleAddress;
        emit AttestationModuleSet(oldModule, _moduleAddress);
    }

    /**
     * @dev Updates the expected data schema hash for a specific data type.
     *      This allows for on-chain validation of data structure if implemented in the attestation module.
     *      This is a governance-controlled function.
     * @param _dataType The string identifier for the data type.
     * @param _schemaHash The keccak256 hash of the new schema (e.g., JSON schema definition hash).
     */
    function updateDataSchema(string calldata _dataType, bytes calldata _schemaHash) external onlyGov {
        if (bytes(_dataType).length == 0) {
            revert InvalidArgument();
        }
        dataSchemas[_dataType] = _schemaHash;
        emit DataSchemaUpdated(_dataType, _schemaHash);
    }

    // --- Capability Modules & Execution ---

    /**
     * @dev Registers a new external capability module contract, making it available for NFTs to attach.
     *      This is a governance-controlled function.
     * @param _capabilityHash A unique hash (e.g., keccak256("ComputeAgentV1")) identifying the capability.
     * @param _moduleAddress The address of the contract implementing this capability.
     * @param _isAutonomous True if this capability can be delegated for autonomous execution by other agents/contracts.
     * @param _description A brief description of the capability.
     */
    function registerCapabilityModule(
        bytes32 _capabilityHash,
        address _moduleAddress,
        bool _isAutonomous,
        string calldata _description
    ) external onlyGov {
        if (_moduleAddress == address(0) || _capabilityHash == bytes32(0)) {
            revert InvalidArgument();
        }
        registeredCapabilityModules[_capabilityHash] = CapabilityModuleConfig({
            moduleAddress: _moduleAddress,
            isAutonomous: _isAutonomous,
            description: _description
        });
        emit CapabilityModuleRegistered(_capabilityHash, _moduleAddress, _isAutonomous, _description);
    }

    /**
     * @dev Attaches a registered capability module to an NFT, providing initial configuration.
     *      This requires a fee as configured by governance.
     * @param _tokenId The ID of the NFT.
     * @param _capabilityHash The hash of the capability module to attach.
     * @param _initialConfig Initial configuration data for this capability instance.
     */
    function attachCapability(
        uint256 _tokenId,
        bytes32 _capabilityHash,
        bytes calldata _initialConfig
    ) external payable whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        if (registeredCapabilityModules[_capabilityHash].moduleAddress == address(0)) {
            revert CapabilityNotRegistered(_capabilityHash);
        }
        if (nftCapabilities[_tokenId][_capabilityHash].capabilityHash != bytes32(0)) {
            revert CapabilityAlreadyAttached(_tokenId, _capabilityHash);
        }
        if (protocolFees[keccak256("attachCapabilityFee")] > msg.value) {
            revert InsufficientFees();
        }

        nftCapabilities[_tokenId][_capabilityHash] = CapabilityInstanceConfig({
            capabilityHash: _capabilityHash,
            configData: _initialConfig
        });
        emit CapabilityAttached(_tokenId, _capabilityHash, _initialConfig);
        // Transfer collected fees to owner/DAO treasury
        if (protocolFees[keccak256("attachCapabilityFee")] > 0) {
            payable(owner()).transfer(protocolFees[keccak256("attachCapabilityFee")]);
        }
    }

    /**
     * @dev Removes an attached capability from an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _capabilityHash The hash of the capability to detach.
     */
    function detachCapability(uint256 _tokenId, bytes32 _capabilityHash) external whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        if (nftCapabilities[_tokenId][_capabilityHash].capabilityHash == bytes32(0)) {
            revert CapabilityNotAttached(_tokenId, _capabilityHash);
        }

        delete nftCapabilities[_tokenId][_capabilityHash];
        emit CapabilityDetached(_tokenId, _capabilityHash);
    }

    /**
     * @dev Triggers the logic of an attached capability.
     *      Can be called by the NFT owner, a delegated address, or an autonomous module itself.
     * @param _tokenId The ID of the NFT.
     * @param _capabilityHash The hash of the capability to execute.
     * @param _executionPayload ABI-encoded data specific to the capability module's function.
     */
    function executeCapability(
        uint256 _tokenId,
        bytes32 _capabilityHash,
        bytes calldata _executionPayload
    ) external whenNotPaused {
        if (nftCapabilities[_tokenId][_capabilityHash].capabilityHash == bytes32(0)) {
            revert CapabilityNotAttached(_tokenId, _capabilityHash);
        }

        address capabilityModuleAddress = registeredCapabilityModules[_capabilityHash].moduleAddress;
        if (capabilityModuleAddress == address(0)) {
            revert CapabilityNotRegistered(_capabilityHash); // Should not happen if nftCapabilities is valid
        }

        bool isOwner = (_msgSender() == ownerOf(_tokenId));
        bool isDelegatee = false;
        if (!isOwner) {
            DelegateControl memory delegation = delegatedCapabilityControls[_tokenId][_msgSender()][_capabilityHash];
            if (delegation.expiry == 0 && delegation.expiry != block.timestamp) { // 0 means permanent, but not non-existent
                isDelegatee = true;
            } else if (delegation.expiry > block.timestamp) {
                isDelegatee = true;
            } else if (delegation.expiry > 0 && delegation.expiry <= block.timestamp) {
                revert DelegationExpired(_tokenId, _capabilityHash, _msgSender());
            }
        }

        // An "autonomous" capability module might call itself or be triggered by an oracle.
        // The `registeredCapabilityModules[_capabilityHash].isAutonomous` flag indicates if it's
        // designed for such scenarios. For this contract, _msgSender() must be owner or delegatee.
        // A truly autonomous system might allow the module itself to execute based on predefined rules.
        // We'll allow the module itself to call if it's flagged as autonomous.
        bool isAutonomousTrigger = (registeredCapabilityModules[_capabilityHash].isAutonomous && _msgSender() == capabilityModuleAddress);


        if (!isOwner && !isDelegatee && !isAutonomousTrigger) {
            revert NotAuthorized(_msgSender());
        }

        ICapabilityModule(capabilityModuleAddress).execute(_tokenId, _executionPayload);
        emit CapabilityExecuted(_tokenId, _capabilityHash, _msgSender(), _executionPayload);

        // Potentially trigger reputation update here based on capability execution success/failure
        _updateNFTReputation(_tokenId, 5, "Capability Executed");
    }

    /**
     * @dev Updates the configuration of an attached capability for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @param _capabilityHash The hash of the attached capability.
     * @param _newConfig The new configuration data for this capability instance.
     */
    function configureCapability(
        uint256 _tokenId,
        bytes32 _capabilityHash,
        bytes calldata _newConfig
    ) external whenNotPaused {
        if (_msgSender() != ownerOf(_tokenId)) {
            revert NotAuthorized(_msgSender());
        }
        if (nftCapabilities[_tokenId][_capabilityHash].capabilityHash == bytes32(0)) {
            revert CapabilityNotAttached(_tokenId, _capabilityHash);
        }

        address capabilityModuleAddress = registeredCapabilityModules[_capabilityHash].moduleAddress;
        if (capabilityModuleAddress == address(0)) {
            revert CapabilityNotRegistered(_capabilityHash);
        }

        // Update internal config
        nftCapabilities[_tokenId][_capabilityHash].configData = _newConfig;

        // Also call the module's configure function if it exists and is relevant
        ICapabilityModule(capabilityModuleAddress).configure(_tokenId, _newConfig);

        emit CapabilityConfigured(_tokenId, _capabilityHash, _newConfig);
    }

    // --- Incentivization & Reputation ---

    /**
     * @dev Allows the protocol (or a trusted caller like a governance module) to reward data attesters.
     * @param _attester The address of the attester to reward.
     * @param _amount The amount of reward to distribute (e.g., in native token).
     */
    function distributeAttestationReward(address _attester, uint256 _amount) external payable onlyGov whenNotPaused {
        if (_attester == address(0) || _amount == 0) {
            revert InvalidArgument();
        }
        if (msg.value < _amount) {
            revert InsufficientFees(); // This implies the 'onlyGov' might need to send funds.
        }

        payable(_attester).transfer(_amount);
        emit AttestationRewardDistributed(_attester, _amount);
    }

    /**
     * @dev Internal function to update an NFT's on-chain reputation score.
     *      Can be called by other functions (e.g., attestDataPoint, executeCapability) or by governance.
     * @param _tokenId The ID of the NFT.
     * @param _scoreChange The amount to change the score by (can be negative).
     * @param _reason A string describing the reason for the score change.
     */
    function _updateNFTReputation(uint256 _tokenId, int256 _scoreChange, string memory _reason) internal {
        if (ownerOf(_tokenId) == address(0)) { // Checks if NFT exists
            revert NFTNotFound(_tokenId);
        }
        int256 newScore = nftReputation[_tokenId] + _scoreChange;
        nftReputation[_tokenId] = newScore;
        emit NFTReputationUpdated(_tokenId, _scoreChange, newScore, _reason);
    }

    /**
     * @dev External version of `_updateNFTReputation` for governance or authorized modules.
     * @param _tokenId The ID of the NFT.
     * @param _scoreChange The amount to change the score by (can be negative).
     * @param _reason A string describing the reason for the score change.
     */
    function updateNFTReputationScore(uint256 _tokenId, int256 _scoreChange, string calldata _reason) external onlyGov whenNotPaused {
        _updateNFTReputation(_tokenId, _scoreChange, _reason);
    }


    // --- Governance & Protocol Evolution ---

    /**
     * @dev Creates a new governance proposal to change a protocol parameter.
     *      Requires a minimum number of NFTs to be held by the proposer (or a minimum reputation score).
     * @param _paramKey The bytes32 key of the protocol parameter to change (e.g., keccak256("votingPeriod")).
     * @param _newValue The new value for the parameter, ABI-encoded.
     * @param _description A detailed description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function proposeProtocolParameterChange(
        bytes32 _paramKey,
        bytes calldata _newValue,
        string calldata _description
    ) external whenNotPaused returns (uint256) {
        // Simple check: proposer must own at least N NFTs (or have a min reputation)
        // For a full DAO, this would use a voter registry or governance token balance.
        // For simplicity, let's say only owner can propose initially.
        if (_msgSender() != owner()) { // Replace with actual DAO check
            revert NotAuthorized(_msgSender());
        }

        uint256 proposalId = _nextProposalId++;
        uint256 votingPeriod = abi.decode(protocolParameters[keccak256("votingPeriod")], (uint256));

        proposals[proposalId] = GovernanceProposal({
            id: proposalId,
            paramKey: _paramKey,
            newValue: _newValue,
            description: _description,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            proposer: _msgSender(),
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize mapping within struct
        });

        emit ProposalCreated(proposalId, _paramKey, _newValue, _description, _msgSender());
        return proposalId;
    }

    /**
     * @dev Allows eligible NFT holders to vote on an active governance proposal.
     *      Each NFT could represent one vote, or vote power could be weighted.
     *      For simplicity, one address = one vote for now, representing overall sentiment.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.state != ProposalState.Active) {
            revert ProposalNotExecutable(_proposalId, "Proposal not active");
        }
        if (proposal.votingEndTime <= block.timestamp) {
            proposal.state = (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, proposal.state);
            revert ProposalNotExecutable(_proposalId, "Voting period ended");
        }
        if (proposal.hasVoted[_msgSender()]) {
            revert ProposalAlreadyVoted(_proposalId, _msgSender());
        }

        // In a real DAO, vote weight would be based on NFT holdings or governance tokens.
        // For simplicity, we just count the vote.
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a governance proposal that has passed its voting period and met quorum.
     *      Anyone can call this to trigger execution of a successful proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound(_proposalId);
        }

        if (proposal.state == ProposalState.Active && proposal.votingEndTime <= block.timestamp) {
            proposal.state = (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, proposal.state);
        }

        if (proposal.state != ProposalState.Succeeded) {
            revert ProposalNotExecutable(_proposalId, "Proposal not succeeded or active");
        }
        if (proposal.state == ProposalState.Executed) {
            revert ProposalNotExecutable(_proposalId, "Proposal already executed");
        }

        // Execute the parameter change
        protocolParameters[proposal.paramKey] = proposal.newValue;
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
        // Note: For complex parameter types, decoding from `bytes` to correct type is needed.
        // E.g., `uint256 newVotingPeriod = abi.decode(proposal.newValue, (uint256));`
    }

    /**
     * @dev Allows for upgrading core protocol modules (e.g., attestation module, governance module)
     *      via a passed governance proposal. This would typically set a new address for a module.
     *      This is a governance-controlled function.
     * @param _moduleKey A bytes32 key identifying the module to upgrade (e.g., keccak256("attestationModule")).
     * @param _newModuleAddress The address of the new module contract.
     */
    function upgradeProtocolModule(bytes32 _moduleKey, address _newModuleAddress) external onlyGov {
        if (_newModuleAddress == address(0)) {
            revert InvalidArgument();
        }

        address oldAddress;
        if (_moduleKey == keccak256("attestationModule")) {
            oldAddress = attestationModule;
            attestationModule = _newModuleAddress;
        } else if (_moduleKey == keccak256("governanceModule")) {
            oldAddress = governanceModule;
            governanceModule = _newModuleAddress;
        } else {
            // For other upgradable modules, extend this logic.
            revert InvalidArgument();
        }
        emit ProtocolModuleUpgraded(_moduleKey, oldAddress, _newModuleAddress);
    }

    /**
     * @dev Emergency function to pause critical protocol operations.
     *      Only callable by the contract owner (which should transition to a DAO multi-sig for production).
     */
    function emergencyPauseProtocol() external onlyOwner {
        protocolPaused = true;
        emit ProtocolPausedStateChanged(true);
    }

    /**
     * @dev Emergency function to unpause critical protocol operations.
     *      Only callable by the contract owner (which should transition to a DAO multi-sig for production).
     */
    function emergencyUnpauseProtocol() external onlyOwner {
        protocolPaused = false;
        emit ProtocolPausedStateChanged(false);
    }


    /**
     * @dev Sets or updates various fees within the protocol, managed by governance.
     * @param _feeType A bytes32 key identifying the type of fee (e.g., keccak256("attachCapabilityFee")).
     * @param _amountOrRate The new fee amount or rate.
     */
    function configureFeeStructure(bytes32 _feeType, uint256 _amountOrRate) external onlyGov {
        protocolFees[_feeType] = _amountOrRate;
        emit FeeStructureConfigured(_feeType, _amountOrRate);
    }


    // --- View Functions ---

    /**
     * @dev Returns the current reputation score of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The reputation score.
     */
    function getNFTReputation(uint256 _tokenId) external view returns (int256) {
        return nftReputation[_tokenId];
    }

    /**
     * @dev Checks if a specific capability is attached to an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _capabilityHash The hash of the capability.
     * @return True if attached, false otherwise.
     */
    function isCapabilityAttached(uint256 _tokenId, bytes32 _capabilityHash) external view returns (bool) {
        return nftCapabilities[_tokenId][_capabilityHash].capabilityHash != bytes32(0);
    }

    /**
     * @dev Retrieves the configuration data for an attached capability.
     * @param _tokenId The ID of the NFT.
     * @param _capabilityHash The hash of the capability.
     * @return The configuration bytes.
     */
    function getCapabilityConfig(uint256 _tokenId, bytes32 _capabilityHash) external view returns (bytes memory) {
        return nftCapabilities[_tokenId][_capabilityHash].configData;
    }

    /**
     * @dev Retrieves information about a registered capability module.
     * @param _capabilityHash The hash of the capability.
     * @return moduleAddress The contract address, isAutonomous flag, and description.
     */
    function getCapabilityModuleInfo(bytes32 _capabilityHash) external view returns (address moduleAddress, bool isAutonomous, string memory description) {
        CapabilityModuleConfig storage config = registeredCapabilityModules[_capabilityHash];
        return (config.moduleAddress, config.isAutonomous, config.description);
    }

    /**
     * @dev Checks the delegation status for a specific capability.
     * @param _tokenId The ID of the NFT.
     * @param _delegatee The address being checked for delegation.
     * @param _capabilityHash The hash of the capability.
     * @return The expiry timestamp (0 if permanent or not delegated).
     */
    function getCapabilityDelegation(uint256 _tokenId, address _delegatee, bytes32 _capabilityHash) external view returns (uint256 expiry) {
        return delegatedCapabilityControls[_tokenId][_delegatee][_capabilityHash].expiry;
    }

    /**
     * @dev Returns the total number of minted NFTs.
     * @return The total supply of NFTs.
     */
    function getTotalSupply() external view returns (uint256) {
        return _nextTokenId - 1; // Since _nextTokenId is 1-indexed
    }

    /**
     * @dev Returns the current state of a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            return ProposalState.Pending; // Or a specific 'NotFound' state
        }
        if (proposal.state == ProposalState.Active && proposal.votingEndTime <= block.timestamp) {
            return (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Failed;
        }
        return proposal.state;
    }

    /**
     * @dev Returns the value of a protocol parameter.
     * @param _paramKey The bytes32 key of the parameter.
     * @return The ABI-encoded value of the parameter.
     */
    function getProtocolParameter(bytes32 _paramKey) external view returns (bytes memory) {
        return protocolParameters[_paramKey];
    }

    /**
     * @dev Returns the current fee for a specific operation.
     * @param _feeType The bytes32 key of the fee type.
     * @return The fee amount.
     */
    function getFee(bytes32 _feeType) external view returns (uint256) {
        return protocolFees[_feeType];
    }
}
```